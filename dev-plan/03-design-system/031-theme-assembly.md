# 031 — Material 3 themes and the theme mode controller

**Phase** 03 · Design system  |  **Depends on** [030](030-color-tokens.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Three `ThemeData` values built from the tokens — light, dark and high-contrast outdoor — plus the persisted controller
that decides which is active. A stock Material widget looks like Tapture with no local styling, and the chosen mode is
restored before the first frame.

## Files

- `frontend/lib/app/theme/app_theme.dart` (new)
- `frontend/lib/app/theme/outdoor_theme.dart` (new)
- `frontend/lib/app/theme/theme_controller.dart` (new)
- `frontend/lib/app/app.dart` (edit)

## Contract

```dart
ThemeData buildTheme({required Brightness brightness, bool outdoor = false});
ThemeData buildOutdoorTheme(Brightness brightness);
enum AppThemeMode { system, light, dark, outdoor }
final themeModeProvider = NotifierProvider<ThemeModeController, AppThemeMode>(...);
```

## Steps

1. Build `ColorScheme`, `TextTheme` and component themes for buttons, fields, chips, dialogs, sheets and app bars from
   tokens only.
2. Derive outdoor by raising contrast, thickening outlines and removing low-contrast surface tints, reusing the same
   token names and identical geometry.
3. Persist the selected mode, restore it before the first frame, and follow the system brightness when the mode is
   `system`.
4. Resolve the mode to a `ThemeData` inside `TaptureApp` so no screen selects a theme itself.

## Constraints

- Outdoor changes contrast only: no padding, radius, size or position differs from light or dark (FE-THEME-03).
- Material is styled once here; a screen that decorates a stock button locally is a defect (FE-THEME-07).
- Reach persistent storage through a `core/` service with an interface and a fake, never a plugin at the call site
  (FE-STR-11).
- Themes get a gallery page and goldens in light, dark and outdoor (FE-CONS-03).

## Definition of done

- [ ] Every stock Material widget already looks like Tapture without local styling.
- [ ] Switching to outdoor changes contrast and outline weight only — a widget test asserts identical geometry against
      light.
- [ ] The chosen mode survives a restart and applies before the first frame, with no visible flash of the wrong theme.
- [ ] Tests: golden of a sample screen in light, dark and outdoor; unit test that `AppThemeMode` round-trips through
      storage; widget test comparing light and outdoor layout geometry.

## Out of scope

- The token values themselves; those are task 030.
- The settings screen control that changes the mode; that belongs to the settings phase.
