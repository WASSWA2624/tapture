# 030 — Design tokens: colour, type, spacing and elevation

**Phase** 03 · Design system  |  **Depends on** [013](../01-orchestration/013-design-token-test.md), [019](../02-foundation/019-app-bootstrap.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The four token files every other widget in the plan reads its style from: the colour palette, the type ramp, the
spacing/radius/size scale and the surface-depth treatment, each resolved for light, dark and outdoor. After this task
no style value is written anywhere else.

## Files

- `frontend/lib/app/theme/color_tokens.dart` (new)
- `frontend/lib/app/theme/typography.dart` (new)
- `frontend/lib/app/theme/dimensions.dart` (new)
- `frontend/lib/app/theme/elevation.dart` (new)

## Contract

```dart
abstract final class AppColors {
  final Color surface, surfaceVariant, background, outline, primary, onPrimary, secondary,
      danger, warning, success, info, confidenceHigh, confidenceMedium, confidenceLow;
}
extension AppColorsX on BuildContext { AppColors get colors; }

abstract final class AppText { static TextStyle display, title, section, body, bodyStrong, label, caption, mono; }

abstract final class Space { static const x1 = 4.0, x2 = 8.0, x3 = 12.0, x4 = 16.0, x6 = 24.0, x8 = 32.0; }
abstract final class Radii { static const sm, md, lg, pill; }
abstract final class Sizes { static const minTapTarget = 48.0, controlHeight = 52.0; }

abstract final class Elevation { static BoxDecoration surface(BuildContext c, {int level = 0}); }
```

## Steps

1. Colours: surface, surfaceVariant, background, outline, primary, onPrimary, secondary, danger, warning, success,
   info and the three confidence-band colours, each given a value in all three modes.
2. Type: display, title, section, body, bodyStrong, label, caption and mono, with weights and line heights chosen for
   reading at arm's length in sunlight.
3. Dimensions: the four-point space scale from 2 to 48, radii small/medium/large/pill, control heights, and
   `minTapTarget` at 48.
4. Elevation: surface levels expressed as tone plus outline rather than shadow, mapped per mode.

## Constraints

- Every token is defined in light, dark **and** outdoor; a token present in one mode only ships as an invisible
  control (FE-THEME-02).
- Semantic role names only — `danger`, `surface`, `outline` — never `red` or `blue700` (FE-THEME-04).
- Contrast is measured, not eyeballed: 4.5:1 body text, 3:1 large text and interactive outlines, in all three modes
  (FE-THEME-10, FE-A11Y-04).
- Swatches, the type ramp and the surface levels each get a widget gallery page and goldens in light, dark and
  outdoor (FE-CONS-03).

## Definition of done

- [x] Changing the active mode restyles every screen with no per-widget work.
- [x] `Color(...)`, `TextStyle(...)`, `EdgeInsets.all(n)`, `BorderRadius.circular(n)` and `Duration(...)` literals are
      absent from feature code; every widget reaches style through these four files (FE-THEME-01).
- [x] Cards, sheets and dialogs share one depth language that survives direct sunlight.
- [x] Tests: unit tests under `frontend/test/design_system/tokens/` asserting the colour, dimension and elevation
      token sets are identical across light, dark and outdoor; golden of the type ramp at default and 200 percent
      text scale.

## Out of scope

- Assembling `ThemeData` or wiring it into the app; that is task 031.
