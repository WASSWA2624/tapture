import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { Resvg } from '@resvg/resvg-js';

// Separate from Tapture's branding inventory: third-party art stays unchanged.
const source = new URL('./source/ai_providers/', import.meta.url);
const output = new URL('../../assets/ai_providers/', import.meta.url);
const check = process.argv.includes('--check');
const hashes = {};
const violations = [];
const digest = (bytes) => createHash('sha256').update(bytes).digest('hex');
for (const name of ['gemini', 'openai', 'openai_inverse', 'xai', 'xai_inverse']) {
  const input = `${name}.${name === 'gemini' ? 'png' : 'svg'}`;
  const original = await readFile(new URL(input, source));
  // Resvg reads the SVG 2 mask presentation attribute, not its CSS spelling.
  // Preserve the source and alpha-mask geometry while adapting that syntax.
  const renderSource = original.toString('utf8').replaceAll(
    'style="mask-type:alpha"', 'mask-type="alpha"',
  );
  const bytes = name === 'gemini'
    ? original
    : new Resvg(renderSource, { fitTo: { mode: 'width', value: 128 } }).render().asPng();
  hashes[name] = { source: input, sourceSha256: digest(original), pngSha256: digest(bytes) };
  const target = new URL(`${name}.png`, output);
  if (check) {
    const actual = await readFile(target).catch(() => null);
    if (!actual || !actual.equals(bytes)) violations.push(`${fileURLToPath(target)}:1: artwork differs`);
  } else {
    await writeFile(target, bytes);
  }
}
const manifest = Buffer.from(`${JSON.stringify({ renderer: '@resvg/resvg-js@2.6.2', alphaMask: 'SVG 2 presentation attribute', assets: hashes }, null, 2)}\n`);
const target = new URL('manifest.json', output);
if (check) {
  const actual = await readFile(target).catch(() => null);
  if (!actual || !actual.equals(manifest)) violations.push(`${fileURLToPath(target)}:1: provenance differs`);
} else {
  await writeFile(target, manifest);
}
if (violations.length) {
  process.stderr.write(`${violations.join('\n')}\n`);
  process.exitCode = 1;
}
