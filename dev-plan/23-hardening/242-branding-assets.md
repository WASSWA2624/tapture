# 242 — App icon, splash and store branding

**Phase** 23 · Hardening  |  **Depends on** [031](../03-design-system/031-theme-assembly.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The Tapture identity applied everywhere the platforms ask for it: launcher icon, Android adaptive icon, splash and store
listing assets, all generated from one vector source per mark and reachable through typed constants.

## Files

- `frontend/assets/branding/` (new)
- `frontend/lib/core/assets/branding_assets.dart` (new)
- `frontend/pubspec.yaml` (edit)

## Steps

1. Keep one vector source per mark and generate every density and platform size from it; no hand-resized bitmap.
2. Keep the icon legible at 48 pixels — no fine detail, no text.
3. Build the splash from theme tokens (046) plus the mark, so it matches light, dark and outdoor rather than baking in
   one background colour.
4. Expose every generated path as a constant in `branding_assets.dart`; no widget or platform file names a raw path.

## Constraints

- Assets are referenced through typed constants only (FE-STR-12).
- The splash uses tokens, never a hardcoded colour (FE-THEME-01).

## Definition of done

- [ ] The icon is recognisable at 48 pixels on a crowded home screen, and the splash matches the active theme in light,
      dark and outdoor.
- [ ] Tests: a test asserting every constant in `branding_assets.dart` resolves to a file that exists, at every density
      the platforms require, and that no declared asset is unreferenced.
