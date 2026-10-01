# 095 — Generate platform branding reproducibly from vector sources

**Implementation step:** 24.56

**Phase** 24 · Product refinements  |  **Depends on** [002](../02-foundation/002-foundation-services.md), [003](../03-design-system/003-design-system.md), [054](054-persist-theme-mode-in-settings-store.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

**Implementation started:** Yes

## Implement

Generate platform branding from one canonical outlined mark and the existing outlined wordmark. Render every raster
directly from vector geometry at its final dimensions; never resize an existing PNG into another density. Resolve
light/dark/outdoor colors through the actual `AppColors` semantic palette. Generate typed asset paths, complete
source/output hashes, native launch resources, icon catalogs and unrestricted web orientation.

The isolated development renderer is **@resvg/resvg-js 2.6.2**, pinned in the package and lockfile and reviewed under
**MPL-2.0** (the installed package metadata and bundled LICENSE agree). Its
[primary project and API](https://github.com/thx/resvg-js) describe direct SVG rendering. The dependency and license
allowlist lives beside this tool and is validated before rendering (FE-FLOW-06). This replaces independently
maintained raster exports without a reproducible generation command; no Flutter runtime package is added.

## Files

- `frontend/tool/branding/{generate.mjs,generate.test.mjs,package.json,package-lock.json,dependencies.json,README.md}`
- `frontend/tool/branding/source/{mark.svg,wordmark.svg}`
- `frontend/lib/core/assets/branding_assets.dart`
- `frontend/assets/branding/` artwork and generation manifest
- Android launcher/adaptive/monochrome densities, launch backgrounds and light/night/Android-12 styles under `res/`
- iOS/macOS icon catalogs; iOS light/dark launch images, named launch color and `LaunchScreen.storyboard`
- Windows ICO; web favicon, standard/maskable/apple-touch icons and manifest
- `frontend/test/core/assets/branding_assets_test.dart`

## Contract

From `frontend/tool/branding/`, `npm ci` installs the pinned renderer; `npm run generate` refreshes resources;
`npm run check` compares every expected output and source hash without writing; `npm test` exercises reproducibility
and negative fixtures. Check reports all missing/stale paths and exits nonzero. The JSON manifest records exact
renderer version, palette roles, input/output SHA-256, byte counts and PNG dimensions. `BrandingAssets` exposes named
runtime artwork and a typed inventory of every generated path.

Native launch follows OS light/dark appearance and uses the matching page background. Outdoor artwork is exposed to
Flutter; an OS launch screen cannot read the app's persisted outdoor setting. No AppDelegate or MainActivity code
is generated. Physical OS mask/launch behavior and recognition remain hardening review evidence, not inferred from
asset dimensions or existence.
Android launch and normal themes use the biometric SDK's required AppCompat DayNight parent in all four resource
variants; light/night palette qualifiers and Android 12 splash artwork remain generated from the same sources.

## Definition of done

- [x] Canonical mark and wordmark geometry render each target size directly, without font installation or raster resizing.
- [x] The exact development renderer version/license is allowlisted and checked against package metadata and lockfile.
- [x] Generated artwork, platform resources, typed inventory and source/output metadata pass a nonmutating cache check.
- [x] AppColors light/dark/outdoor roles match generated metadata and native launch backgrounds; web permits either orientation.
- [x] Tests: Node fixtures prove reproducibility and reject missing densities/assets, source/palette changes and unpinned renderer declarations; Dart validates typed inventory, source/output hashes and semantic colors.
- [ ] Physical review: reference devices show recognizable 48-pixel marks, correct OS masking and matching native/Flutter launch backgrounds in supported appearance modes.

## Verification — 2026-10-01

The final generator emitted 95 resources and `npm run check` reports zero missing/stale outputs without writing.
All five Node fixtures pass, including source/palette invalidation, missing densities, metadata/native appearance,
and dependency/license allowlist failures. Both Dart inventory/hash/palette tests pass in the final focused batch;
typed paths and assertions also analyzed cleanly. The installation audit initially reported zero vulnerabilities;
a later audit could not reach the registry because DNS resolution failed. Physical review remains open.
The AppCompat integration refresh regenerated all 95 resources, passed the nonmutating cache check and all five
Node fixtures, including explicit parent/background/Android 12 assertions. The final Dart/native reruns remain pending.
