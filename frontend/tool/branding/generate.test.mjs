import assert from "node:assert/strict";
import {
  mkdtemp,
  mkdir,
  copyFile,
  readFile,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { inflateSync } from "node:zlib";
import {
  buildAssets,
  frontendRoot,
  generate,
  readPalette,
} from "./generate.mjs";

async function fixture(context) {
  const root = await mkdtemp(path.join(os.tmpdir(), "tapture-branding-"));
  context.after(async () => {
    assert.equal(path.dirname(root), path.resolve(os.tmpdir()));
    assert.ok(path.basename(root).startsWith("tapture-branding-"));
    await rm(root, { recursive: true, force: true });
  });
  for (const input of [
    "tool/branding/source/mark.svg",
    "tool/branding/source/wordmark.svg",
    "lib/app/theme/color_tokens.dart",
    "tool/branding/generate.mjs",
    "tool/branding/package.json",
    "tool/branding/package-lock.json",
    "tool/branding/dependencies.json",
  ]) {
    const destination = path.join(root, input);
    await mkdir(path.dirname(destination), { recursive: true });
    await copyFile(path.join(frontendRoot, input), destination);
  }
  return root;
}

function firstPixel(png) {
  assert.equal(png[24], 8, "8-bit PNG");
  assert.equal(png[25], 6, "RGBA PNG");
  const chunks = [];
  for (let offset = 8; offset < png.length;) {
    const length = png.readUInt32BE(offset);
    if (png.toString("ascii", offset + 4, offset + 8) === "IDAT")
      chunks.push(png.subarray(offset + 8, offset + 8 + length));
    offset += 12 + length;
  }
  // All PNG row filters have zero left/above predictors at the first pixel.
  return [...inflateSync(Buffer.concat(chunks)).subarray(1, 5)];
}

test("all sizes render reproducibly from vectors; metadata and platform themes agree", async (context) => {
  const root = await fixture(context);
  const assets = await buildAssets(root);
  const again = await buildAssets(root);
  for (const [output, bytes] of assets)
    assert.deepEqual(again.get(output), bytes, output);
  const manifest = JSON.parse(assets.get("assets/branding/manifest.json"));
  for (const [density, factor] of [
    ["mdpi", 1],
    ["hdpi", 1.5],
    ["xhdpi", 2],
    ["xxhdpi", 3],
    ["xxxhdpi", 4],
  ]) {
    assert.equal(
      manifest.outputs[
        `android/app/src/main/res/mipmap-${density}/ic_launcher.png`
      ].width,
      48 * factor,
    );
    for (const theme of ["", "-night"])
      assert.equal(
        manifest.outputs[
          `android/app/src/main/res/drawable${theme}-${density}/splash_mark.png`
        ].width,
        288 * factor,
      );
  }
  const opaque = assets.get(
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png",
  );
  const primary = manifest.palette.light.primary;
  assert.deepEqual(firstPixel(opaque), [
    parseInt(primary.slice(1, 3), 16),
    parseInt(primary.slice(3, 5), 16),
    parseInt(primary.slice(5, 7), 16),
    255,
  ]);
  assert.equal(manifest.outputs["web/icons/Icon-maskable-512.png"].width, 512);
  assert.equal(JSON.parse(assets.get("web/manifest.json")).orientation, "any");
  for (const [qualifier, theme] of [["values", "light"], ["values-night", "dark"]]) {
    const colors = assets.get(`android/app/src/main/res/${qualifier}/colors.xml`).toString();
    assert.ok(colors.includes(manifest.palette[theme].background));
    for (const modern of [false, true]) {
      const styles = assets.get(`android/app/src/main/res/${qualifier}${modern ? "-v31" : ""}/styles.xml`).toString();
      assert.equal((styles.match(/parent="Theme.AppCompat.DayNight.NoActionBar"/g) ?? []).length, 2);
      assert.ok(styles.includes('@drawable/launch_background'));
      assert.ok(styles.includes('@color/splash_background'));
      assert.equal(styles.includes('android:windowSplashScreenAnimatedIcon'), modern);
    }
  }
  assert.match(
    assets.get("ios/Runner/Base.lproj/LaunchScreen.storyboard").toString(),
    /name="LaunchBackground"/,
  );
  const colors = JSON.parse(
    assets.get(
      "ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json",
    ),
  );
  assert.equal(colors.colors[1].appearances[0].value, "dark");
  assert.ok(
    !assets
      .get("assets/branding/tapture-mark.svg")
      .toString()
      .includes("currentColor"),
  );
  await generate({ root });
  assert.deepEqual((await generate({ root, check: true })).violations, []);
});

test("check lists every missing density and asset without replacing anything", async (context) => {
  const root = await fixture(context);
  await generate({ root });
  const missing = [
    "android/app/src/main/res/drawable-mdpi/splash_mark.png",
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
    "web/icons/Icon-maskable-192.png",
  ];
  for (const output of missing) await rm(path.join(root, output));
  const before = await stat(path.join(root, "assets/branding/manifest.json"));
  const result = await generate({ root, check: true });
  assert.deepEqual(
    result.violations.sort(),
    missing.map((output) => `${output}: missing generated resource`).sort(),
  );
  assert.equal(
    (await stat(path.join(root, "assets/branding/manifest.json"))).mtimeMs,
    before.mtimeMs,
  );
});

test("changing canonical geometry or assembled palette invalidates cached resources", async (context) => {
  const root = await fixture(context);
  await generate({ root });
  const mark = path.join(root, "tool/branding/source/mark.svg");
  await writeFile(
    mark,
    (await readFile(mark, "utf8")).replace('r="222"', 'r="221"'),
  );
  const sourceChanged = await generate({ root, check: true });
  assert.ok(
    sourceChanged.violations.includes(
      "assets/branding/manifest.json: stale generated resource",
    ),
  );
  assert.ok(
    sourceChanged.violations.includes(
      "web/icons/Icon-512.png: stale generated resource",
    ),
  );
  await generate({ root });
  const palette = path.join(root, "lib/app/theme/color_tokens.dart");
  await writeFile(
    palette,
    (await readFile(palette, "utf8")).replace(
      "Color(0xFF075E54)",
      "Color(0xFF064D45)",
    ),
  );
  const colorsChanged = await generate({ root, check: true });
  assert.ok(
    colorsChanged.violations.includes(
      "android/app/src/main/res/mipmap-mdpi/ic_launcher.png: stale generated resource",
    ),
  );
  assert.ok(
    colorsChanged.violations.includes(
      "assets/branding/manifest.json: stale generated resource",
    ),
  );
});

test("unresolved color roles fail rather than introducing an untracked default", async () => {
  const source = await readFile(
    path.join(frontendRoot, "lib/app/theme/color_tokens.dart"),
    "utf8",
  );
  assert.throws(
    () =>
      readPalette(
        source.replace("primary: _headerLight,", "primary: unknownToken,"),
      ),
    /has no tracked opaque color token/,
  );
});

test("renderer changes require matching the dependency and license allowlist", async (context) => {
  const root = await fixture(context);
  const filename = path.join(root, "tool/branding/package.json");
  const declared = JSON.parse(await readFile(filename, "utf8"));
  declared.devDependencies["@resvg/resvg-js"] = "^2.6.2";
  await writeFile(filename, JSON.stringify(declared));
  await assert.rejects(
    buildAssets(root),
    /pinned dependency, lockfile and reviewed license allowlist/,
  );
});
