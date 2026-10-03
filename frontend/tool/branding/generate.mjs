import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import { Resvg } from "@resvg/resvg-js";

const renderer = createRequire(import.meta.url)("@resvg/resvg-js/package.json");

export const frontendRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../..",
);
const tool = "tool/branding";
const manifestPath = "assets/branding/manifest.json";
const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");
const json = (value) => `${JSON.stringify(value, null, 2)}\n`;
const text = (value) => Buffer.from(value, "utf8");
const densities = [
  ["mdpi", 1],
  ["hdpi", 1.5],
  ["xhdpi", 2],
  ["xxhdpi", 3],
  ["xxxhdpi", 4],
];
const iosIcons = [
  ["20x20", 20, [1, 2, 3]],
  ["29x29", 29, [1, 2, 3]],
  ["40x40", 40, [1, 2, 3]],
  ["60x60", 60, [2, 3]],
  ["76x76", 76, [1, 2]],
  ["83.5x83.5", 83.5, [2]],
  ["1024x1024", 1024, [1]],
];

/// Resolve public semantic roles through the actual Dart palette assembly.
export function readPalette(source) {
  const constants = new Map(
    [
      ...source.matchAll(/const Color (\w+) = Color\(0xFF([\dA-Fa-f]{6})\);/g),
    ].map((match) => [match[1], `#${match[2].toUpperCase()}`]),
  );
  const palette = {};
  for (const theme of ["light", "dark", "outdoor"]) {
    const body = source.match(
      new RegExp(
        `static const AppColors ${theme} = AppColors\\(([\\s\\S]*?)\\n  \\);`,
      ),
    )?.[1];
    if (!body) throw new Error(`AppColors.${theme} is missing`);
    palette[theme] = {};
    for (const role of ["background", "primary", "onPrimary", "onSurface"]) {
      const token = body.match(new RegExp(`\\b${role}: (\\w+),`))?.[1];
      const color = constants.get(token);
      if (!color)
        throw new Error(
          `AppColors.${theme}.${role} has no tracked opaque color token`,
        );
      palette[theme][role] = color;
    }
  }
  return palette;
}

function geometry(svg) {
  if (/<(?:image|text|script|foreignObject)\b|(?:href|url)\s*[=(]/i.test(svg)) {
    throw new Error(
      "Canonical branding must contain only self-contained vector geometry",
    );
  }
  const viewBox = svg.match(/viewBox="([^"]+)"/)?.[1];
  const body = svg
    .replace(/^[\s\S]*?<svg\b[^>]*>/, "")
    .replace(/<\/svg>\s*$/, "")
    .replace(/<title>[\s\S]*?<\/title>\s*/, "")
    .trim();
  if (!viewBox || !body || !body.includes("currentColor"))
    throw new Error("Invalid canonical vector");
  return { viewBox, body };
}

function square(mark, color, { background, fraction = 1 } = {}) {
  const size = 1024 * fraction;
  const inset = (1024 - size) / 2;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024" role="img" aria-label="Tapture"><title>Tapture</title>${background ? `<rect width="1024" height="1024" fill="${background}"/>` : ""}<svg x="${inset}" y="${inset}" width="${size}" height="${size}" viewBox="${mark.viewBox}">${mark.body.replaceAll("currentColor", color)}</svg></svg>\n`;
}

function lockup(mark, words, markColor, ink, stacked = false) {
  const viewBox = stacked ? "-229.68 0 1277.37 1337.69" : "0 0 3008.84 818";
  const size = stacked
    ? 'width="1277.37" height="1337.69"'
    : 'width="3008.84" height="818"';
  // Preserve the published stacked lettering scale and placement.
  const wordTransform = stacked
    ? ' transform="translate(-919.5341446691807 828.7150428522455) scale(0.6537538567020912)"'
    : "";
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}" ${size} role="img" aria-label="Tapture"><title>Tapture</title><svg width="818" height="818" viewBox="${mark.viewBox}">${mark.body.replaceAll("currentColor", markColor)}</svg><g${wordTransform}>${words.body.replaceAll("currentColor", ink)}</g></svg>\n`;
}

/// Render the vector at the requested size. Never read a generated raster.
function png(svg, size) {
  return Buffer.from(
    new Resvg(svg, {
      fitTo: { mode: "width", value: size },
      font: { loadSystemFonts: false },
    })
      .render()
      .asPng(),
  );
}

function ico(svg) {
  const sizes = [16, 24, 32, 48, 64, 128, 256];
  const images = sizes.map((size) => png(svg, size));
  const header = Buffer.alloc(6 + 16 * sizes.length);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(sizes.length, 4);
  let offset = header.length;
  for (let index = 0; index < sizes.length; index++) {
    const entry = 6 + 16 * index;
    header[entry] = sizes[index] === 256 ? 0 : sizes[index];
    header[entry + 1] = header[entry];
    header.writeUInt16LE(1, entry + 4);
    header.writeUInt16LE(32, entry + 6);
    header.writeUInt32LE(images[index].length, entry + 8);
    header.writeUInt32LE(offset, entry + 12);
    offset += images[index].length;
  }
  return Buffer.concat([header, ...images]);
}

function colorComponents(hex) {
  const channels = [1, 3, 5].map((offset) =>
    (parseInt(hex.slice(offset, offset + 2), 16) / 255).toFixed(6),
  );
  return {
    alpha: "1.000000",
    red: channels[0],
    green: channels[1],
    blue: channels[2],
  };
}

function styles(modern = false) {
  // The biometric SDK requires AppCompat; resource qualifiers still select the
  // existing OS light/dark palette, icon and launch background.
  return `<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <style name="LaunchTheme" parent="Theme.AppCompat.DayNight.NoActionBar">\n        <item name="android:windowBackground">@drawable/launch_background</item>\n${modern ? '        <item name="android:windowSplashScreenBackground">@color/splash_background</item>\n        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_mark</item>\n        <item name="android:windowSplashScreenAnimationDuration">0</item>\n' : ""}    </style>\n    <style name="NormalTheme" parent="Theme.AppCompat.DayNight.NoActionBar">\n        <item name="android:windowBackground">@color/splash_background</item>\n    </style>\n</resources>\n`;
}

function storyboard(background) {
  const components = colorComponents(background);
  return `<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="15712" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" colorMatched="YES" initialViewController="01J-lp-oVM">\n    <dependencies><deployment identifier="iOS"/><plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="15704"/><capability name="Named colors" minToolsVersion="9.0"/></dependencies>\n    <scenes><scene sceneID="EHf-IW-A2E"><objects>\n        <viewController id="01J-lp-oVM" sceneMemberID="viewController"><view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3"><rect key="frame" x="0.0" y="0.0" width="414" height="896"/><autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>\n            <subviews><imageView opaque="NO" clipsSubviews="YES" contentMode="center" image="LaunchImage" translatesAutoresizingMaskIntoConstraints="NO" id="YRO-k0-Ey4"/></subviews>\n            <color key="backgroundColor" name="LaunchBackground"/>\n            <constraints><constraint firstItem="YRO-k0-Ey4" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="1a2-6s-vTC"/><constraint firstItem="YRO-k0-Ey4" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="4X2-HB-R7a"/></constraints>\n        </view></viewController><placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>\n    </objects></scene></scenes>\n    <resources><image name="LaunchImage" width="192" height="192"/><namedColor name="LaunchBackground"><color red="${components.red}" green="${components.green}" blue="${components.blue}" alpha="1" colorSpace="custom" customColorSpace="sRGB"/></namedColor></resources>\n</document>\n`;
}

function constants(paths) {
  const names = {
    mark: "tapture-mark.svg",
    markInverse: "tapture-mark-inverse.svg",
    markPng: "tapture-mark-512.png",
    markInversePng: "tapture-mark-inverse-512.png",
    lockup: "tapture-lockup-horizontal.svg",
    lockupInverse: "tapture-lockup-horizontal-inverse.svg",
    lockupStacked: "tapture-lockup-stacked.svg",
    lockupPng: "tapture-lockup-horizontal-2048.png",
    splashLight: "splash-light.svg",
    splashDark: "splash-dark.svg",
    splashOutdoor: "splash-outdoor.svg",
    favicon: "favicon.svg",
    manifest: "manifest.json",
  };
  let source =
    "// Generated by tool/branding/generate.mjs. Do not edit.\n\n/// Typed paths for runtime artwork and the complete generated resource inventory.\nabstract final class BrandingAssets {\n";
  for (const [name, filename] of Object.entries(names)) {
    const declaration = `  static const String ${name} = 'assets/branding/${filename}';`;
    source += `  /// The ${name} resource.\n${declaration.length <= 80 ? declaration : `  static const String ${name} =\n      'assets/branding/${filename}';`}\n\n`;
  }
  source +=
    "  /// Every generated path; platform resources are bundled by their toolchains.\n  static const List<String> generated = <String>[\n";
  source += [...paths, manifestPath]
    .sort()
    .map((output) => `    '${output}',\n`)
    .join("");
  return `${source}  ];\n}\n`;
}

export async function buildAssets(root = frontendRoot) {
  const inputs = [
    `${tool}/source/mark.svg`,
    `${tool}/source/wordmark.svg`,
    "lib/app/theme/color_tokens.dart",
    `${tool}/generate.mjs`,
    `${tool}/package.json`,
    `${tool}/package-lock.json`,
    `${tool}/dependencies.json`,
  ];
  const sourceBytes = new Map(
    await Promise.all(
      inputs.map(async (input) => [
        input,
        await readFile(path.join(root, input)),
      ]),
    ),
  );
  const declared = JSON.parse(sourceBytes.get(`${tool}/package.json`));
  const locked = JSON.parse(sourceBytes.get(`${tool}/package-lock.json`));
  const allowed = JSON.parse(sourceBytes.get(`${tool}/dependencies.json`));
  const dependency = allowed[renderer.name];
  if (
    !dependency ||
    dependency.version !== renderer.version ||
    dependency.license !== renderer.license ||
    declared.devDependencies[renderer.name] !== renderer.version ||
    locked.packages[`node_modules/${renderer.name}`]?.version !==
      renderer.version
  ) {
    throw new Error(
      "Branding renderer must match its pinned dependency, lockfile and reviewed license allowlist",
    );
  }
  const mark = geometry(sourceBytes.get(inputs[0]).toString());
  const words = geometry(sourceBytes.get(inputs[1]).toString());
  const palette = readPalette(sourceBytes.get(inputs[2]).toString());
  const assets = new Map();
  const addText = (output, value) => assets.set(output, text(value));
  const addPng = (output, svg, size) => assets.set(output, png(svg, size));
  const light = square(mark, palette.light.primary);
  const inverse = square(mark, palette.light.onPrimary);
  const icon = square(mark, palette.light.onPrimary, {
    background: palette.light.primary,
    fraction: 0.76,
  });
  const maskable = square(mark, palette.light.onPrimary, {
    background: palette.light.primary,
    fraction: 0.54,
  });
  const foreground = square(mark, palette.light.onPrimary, { fraction: 0.54 });
  const horizontal = lockup(
    mark,
    words,
    palette.light.primary,
    palette.light.onSurface,
  );
  for (const [name, svg] of Object.entries({
    "tapture-mark.svg": light,
    "tapture-mark-inverse.svg": inverse,
    "tapture-lockup-horizontal.svg": horizontal,
    "tapture-lockup-horizontal-inverse.svg": lockup(
      mark,
      words,
      palette.light.onPrimary,
      palette.dark.onSurface,
    ),
    "tapture-lockup-stacked.svg": lockup(
      mark,
      words,
      palette.light.primary,
      palette.light.onSurface,
      true,
    ),
    "favicon.svg": light,
    "splash-light.svg": square(mark, palette.light.primary, {
      background: palette.light.background,
      fraction: 0.42,
    }),
    "splash-dark.svg": square(mark, palette.dark.primary, {
      background: palette.dark.background,
      fraction: 0.42,
    }),
    "splash-outdoor.svg": square(mark, palette.outdoor.primary, {
      background: palette.outdoor.background,
      fraction: 0.42,
    }),
  }))
    addText(`assets/branding/${name}`, svg);
  addPng("assets/branding/tapture-mark-512.png", light, 512);
  addPng("assets/branding/tapture-mark-inverse-512.png", inverse, 512);
  addPng(
    "assets/branding/tapture-lockup-horizontal-2048.png",
    horizontal,
    2048,
  );
  for (const [density, factor] of densities) {
    const base = "android/app/src/main/res";
    addPng(`${base}/mipmap-${density}/ic_launcher.png`, icon, 48 * factor);
    addPng(
      `${base}/drawable-${density}/ic_launcher_foreground.png`,
      foreground,
      108 * factor,
    );
    addPng(
      `${base}/drawable-${density}/ic_launcher_monochrome.png`,
      foreground,
      108 * factor,
    );
    addPng(
      `${base}/drawable-${density}/ic_launcher_background.png`,
      square(mark, palette.light.primary, {
        background: palette.light.primary,
        fraction: 0.54,
      }),
      108 * factor,
    );
    addPng(
      `${base}/drawable-${density}/splash_mark.png`,
      square(mark, palette.light.primary, { fraction: 0.42 }),
      288 * factor,
    );
    addPng(
      `${base}/drawable-night-${density}/splash_mark.png`,
      square(mark, palette.dark.primary, { fraction: 0.42 }),
      288 * factor,
    );
  }
  for (const [name, theme] of [
    ["values", "light"],
    ["values-night", "dark"],
  ]) {
    addText(
      `android/app/src/main/res/${name}/colors.xml`,
      `<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="splash_background">${palette[theme].background}</color>\n</resources>\n`,
    );
    addText(
      `android/app/src/main/res/${name}/styles.xml`,
      styles(),
    );
    addText(
      `android/app/src/main/res/${name}-v31/styles.xml`,
      styles(true),
    );
  }
  const launch =
    '<?xml version="1.0" encoding="utf-8"?>\n<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n    <item android:drawable="@color/splash_background"/>\n    <item><bitmap android:gravity="center" android:src="@drawable/splash_mark"/></item>\n</layer-list>\n';
  for (const qualifier of ["drawable", "drawable-v21"])
    addText(
      `android/app/src/main/res/${qualifier}/launch_background.xml`,
      launch,
    );
  addText(
    "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml",
    '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n    <background android:drawable="@drawable/ic_launcher_background"/>\n    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n</adaptive-icon>\n',
  );
  const iosImages = [];
  for (const [sizeName, size, scales] of iosIcons) {
    for (const scale of scales) {
      const filename = `Icon-App-${sizeName}@${scale}x.png`;
      addPng(
        `ios/Runner/Assets.xcassets/AppIcon.appiconset/${filename}`,
        icon,
        size * scale,
      );
      const idioms =
        size === 1024
          ? ["ios-marketing"]
          : size >= 76
            ? ["ipad"]
            : size === 60
              ? ["iphone"]
              : scale === 3
                ? ["iphone"]
                : scale === 1 && size !== 29
                  ? ["ipad"]
                  : ["iphone", "ipad"];
      for (const idiom of idioms)
        iosImages.push({ size: sizeName, idiom, filename, scale: `${scale}x` });
    }
  }
  addText(
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json",
    json({ images: iosImages, info: { version: 1, author: "xcode" } }),
  );
  const launchImages = [];
  for (const scale of [1, 2, 3]) {
    for (const theme of ["light", "dark"]) {
      const filename = `LaunchImage${theme === "dark" ? "-dark" : ""}${scale > 1 ? `@${scale}x` : ""}.png`;
      addPng(
        `ios/Runner/Assets.xcassets/LaunchImage.imageset/${filename}`,
        square(mark, palette[theme].primary, { fraction: 0.76 }),
        192 * scale,
      );
      launchImages.push({
        idiom: "universal",
        filename,
        scale: `${scale}x`,
        ...(theme === "dark"
          ? { appearances: [{ appearance: "luminosity", value: "dark" }] }
          : {}),
      });
    }
  }
  addText(
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json",
    json({ images: launchImages, info: { version: 1, author: "xcode" } }),
  );
  addText(
    "ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json",
    json({
      colors: ["light", "dark"].map((theme) => ({
        idiom: "universal",
        ...(theme === "dark"
          ? { appearances: [{ appearance: "luminosity", value: "dark" }] }
          : {}),
        color: {
          "color-space": "srgb",
          components: colorComponents(palette[theme].background),
        },
      })),
      info: { version: 1, author: "xcode" },
    }),
  );
  addText(
    "ios/Runner/Base.lproj/LaunchScreen.storyboard",
    storyboard(palette.light.background),
  );
  const macImages = [];
  for (const size of [16, 32, 64, 128, 256, 512, 1024])
    addPng(
      `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_${size}.png`,
      icon,
      size,
    );
  for (const size of [16, 32, 128, 256, 512])
    for (const scale of [1, 2])
      macImages.push({
        size: `${size}x${size}`,
        idiom: "mac",
        filename: `app_icon_${size * scale}.png`,
        scale: `${scale}x`,
      });
  addText(
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json",
    json({ images: macImages, info: { version: 1, author: "xcode" } }),
  );
  assets.set("windows/runner/resources/app_icon.ico", ico(icon));
  for (const size of [192, 512]) {
    addPng(`web/icons/Icon-${size}.png`, icon, size);
    addPng(`web/icons/Icon-maskable-${size}.png`, maskable, size);
  }
  addPng("web/icons/apple-touch-icon.png", icon, 180);
  addPng("web/favicon.png", light, 32);
  addText("web/favicon.svg", light);
  addText(
    "web/manifest.json",
    json({
      name: "Tapture",
      short_name: "Tapture",
      start_url: ".",
      display: "standalone",
      background_color: palette.light.background,
      theme_color: palette.light.primary,
      description: "Tap it. It's data.",
      orientation: "any",
      prefer_related_applications: false,
      icons: [192, 512].flatMap((size) => [
        {
          src: `icons/Icon-${size}.png`,
          sizes: `${size}x${size}`,
          type: "image/png",
          purpose: "any",
        },
        {
          src: `icons/Icon-maskable-${size}.png`,
          sizes: `${size}x${size}`,
          type: "image/png",
          purpose: "maskable",
        },
      ]),
    }),
  );
  addText(
    "lib/core/assets/branding_assets.dart",
    constants([...assets.keys(), "lib/core/assets/branding_assets.dart"]),
  );
  const manifest = {
    version: 1,
    renderer: `${renderer.name}@${renderer.version}`,
    palette,
    sources: Object.fromEntries(
      [...sourceBytes].map(([input, bytes]) => [input, sha256(bytes)]),
    ),
    outputs: Object.fromEntries(
      [...assets]
        .sort(([left], [right]) => left.localeCompare(right))
        .map(([output, bytes]) => [
          output,
          {
            sha256: sha256(bytes),
            bytes: bytes.length,
            ...(output.endsWith(".png")
              ? {
                  width: bytes.readUInt32BE(16),
                  height: bytes.readUInt32BE(20),
                }
              : {}),
          },
        ]),
    ),
  };
  addText(manifestPath, json(manifest));
  return assets;
}

export async function generate({ root = frontendRoot, check = false } = {}) {
  const assets = await buildAssets(root);
  const violations = [];
  for (const [output, bytes] of assets) {
    const destination = path.join(root, output);
    if (check) {
      try {
        if (!(await readFile(destination)).equals(bytes))
          violations.push(`${output}: stale generated resource`);
      } catch (error) {
        if (error.code === "ENOENT")
          violations.push(`${output}: missing generated resource`);
        else throw error;
      }
    } else {
      await mkdir(path.dirname(destination), { recursive: true });
      await writeFile(destination, bytes);
    }
  }
  return { count: assets.size, violations };
}

if (
  process.argv[1] &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const args = process.argv.slice(2);
  if (args.some((argument) => argument !== "--check"))
    throw new Error("usage: node tool/branding/generate.mjs [--check]");
  const result = await generate({ check: args.includes("--check") });
  for (const violation of result.violations) console.error(violation);
  console.log(
    `${result.count} branding resources; ${result.violations.length} violations.`,
  );
  process.exitCode = result.violations.length === 0 ? 0 : 1;
}
