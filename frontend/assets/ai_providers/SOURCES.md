# Provider artwork

Acquired 2026-10-08 for the provider selector in task 144. Marks identify the
corresponding service beside its readable account name; they imply no affiliation
or endorsement and are never Tapture branding. No runtime image requests occur.

| Asset | Official source | Terms |
| --- | --- | --- |
| `gemini.png` | [Google products](https://about.google/products/), [original product PNG](https://www.gstatic.com/marketing-cms/assets/images/a4/97/92c1ec494d129f3fb8d7caa91584/gemini-update.png) | [Product compatibility and legal attribution](https://partnermarketinghub.withgoogle.com/brands/google/use-cases/product-co-branding/) |
| `openai.png`, `openai_inverse.png` | [OpenAI brand download](https://cdn.openai.com/brand/OpenAI-Logos-2025.zip), `OpenAI-black-monoblossom.svg` / `OpenAI-white-monoblossom.svg` | [OpenAI brand usage terms](https://openai.com/brand/#usage-terms) |
| `xai.png`, `xai_inverse.png` | [Official docs light SVG](https://docs.x.ai/_next/static/media/favicon-light.1u6watcuoe8mg.svg) / [dark SVG](https://docs.x.ai/_next/static/media/favicon-dark.0-f2gt9doy0_1.svg) | [xAI brand guidelines](https://x.ai/legal/brand-guidelines) |

Gemini is a trademark of Google LLC. OpenAI's marks belong to OpenAI; xAI/Grok
marks belong to their owner. Published brand terms apply, including accurate
service identification, unchanged artwork, and withdrawal of permission.

The original PNG/SVG bytes are retained in
`frontend/tool/branding/source/ai_providers/`. Gemini is copied byte-for-byte;
the supplied monochrome variants are rasterized without geometry or color edits
at 128px with the repository's pinned `@resvg/resvg-js` 2.6.2.
Run `node generate_ai_providers.mjs` (or `--check`) from
`frontend/tool/branding/`. This separate command never changes Tapture branding.
`manifest.json` records SHA-256 of every original and runtime PNG.
The renderer maps the SVG 2 alpha-mask CSS spelling to its presentation attribute
so Resvg preserves opaque masks. Original source bytes and geometry are unchanged.
OpenAI's downloaded ZIP SHA-256 is
`b2c4cd1e86bbe76bdc4946a72d014efa455240c177f4878fd68cc9b88c71d2ec`.

xAI's newer brand ZIP was inaccessible from this host (HTTP block). The two
unchanged official docs marks explicitly named by the approved prompt were
available. Release review must confirm their continued approval under the
current download-only terms; task 144 leaves artwork approval acceptance open
until that is verified.
