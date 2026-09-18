# 300 — Soften input placeholder text

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Add `onSurfaceMuted` so empty-field hints and resting labels read quieter
than typed text in every theme, while still clearing 4.5:1. Floating
labels and typed values stay on `onSurface`. Field widgets are unchanged.

## Files

- `frontend/lib/app/theme/color_tokens.dart`
- `frontend/lib/app/theme/app_theme.dart`
- `frontend/lib/app/theme/color_swatches.dart`
- `frontend/test/design_system/tokens/color_tokens_test.dart`
- `frontend/test/app/theme/app_theme_test.dart`

## Constraints

- One new semantic role in all three palettes (FE-THEME-02, FE-THEME-04,
  FE-THEME-11). Style Material centrally (FE-THEME-07).
- Reuse `_outlineLight` and `_outlineDark`; outdoor uses `0xFF3B4A54`
  (FE-THEME-03, FE-THEME-10).
- Do not change field widgets or anything under `lib/features/`.
- Extend the token contrast guardrail; do not weaken it (FE-TEST-06).

## Definition of done

- [x] Hint text and resting labels use `onSurfaceMuted` in light, dark
      and outdoor. Floating labels and typed text stay on `onSurface`.
- [x] `onSurfaceMuted` meets 4.5:1 on every surface in every mode.
- [x] Tests: role present; muted contrast; theme hint/label vs floating
      and typed ink.
