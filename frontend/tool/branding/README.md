# Branding resources

Run `npm ci` here, then `npm run generate` or `npm run check`.
Run `npm test` for the reproducibility and negative fixtures.

`source/mark.svg` is the only mark geometry. The wordmark retains its outlined
vector lettering in `source/wordmark.svg`; no font installation is needed.
Every PNG is rendered directly from these vectors at its final pixel size with
the pinned resvg renderer. PNGs are never resized into other densities.

The generator reads light, dark and outdoor semantic colors from
`lib/app/theme/color_tokens.dart`. Its manifest records the source, palette,
renderer, generator and output hashes. `--check` recomputes the complete output
inventory and reports every missing or changed resource without writing files.
Use generation after a source or palette change; do not patch generated icons.

Native launch colors follow the OS light/dark setting. Outdoor launch behavior
requires an in-app setting and cannot be selected by a platform launch screen;
the outdoor SVG is available to Flutter through `BrandingAssets`.
Physical home-screen recognition, OS cropping and launch transitions still need
review on the reference devices.

The isolated development dependency is allowlisted in `dependencies.json`:
`@resvg/resvg-js` 2.6.2, MPL-2.0, checked against the installed package and lockfile.
It replaces unrepeatable manual raster exports and adds no Flutter dependency.
