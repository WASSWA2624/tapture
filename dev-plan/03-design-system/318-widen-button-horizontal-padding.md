# 318 — Widen button horizontal padding

**Phase** 03 · Design system  |  **Depends on** [031](031-theme-assembly.md), [034](034-app-button.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Every labelled button keeps a comfortable gap between its label and its outline. Filled, outlined and
text buttons share one horizontal padding token. Icon buttons, the floating button and the primary
action's full-width layout stay as they are.

## Files

- `frontend/lib/app/theme/app_theme.dart`
- `frontend/test/app/theme/app_theme_test.dart`
- `frontend/test/core/widgets/app_button_test.dart`
- `frontend/test/design_system/` goldens that draw a labelled button (`app_button_*`,
  `app_dialog_*`, `app_empty_state_*`, `app_error_state_*`, `app_section_header_*`,
  `theme_preview_*`, `widget_gallery_index_*`, `gallery_index_*`). `app_form_*` was
  regenerated and stayed identical because submit uses `AppPrimaryAction`.

## Constraints

- Style Material once, in `app_theme.dart`; no per-screen padding (FE-THEME-07).
- A token value, never a literal (FE-THEME-01, FE-THEME-11).
- Outdoor keeps identical geometry (FE-THEME-03).
- 48 dp targets, and labels wrap rather than clip at 200 percent (FE-A11Y-01, FE-A11Y-03).
- Labels 35 percent longer still fit (FE-L10N-06).
- Catalogue goldens in all three themes (FE-CONS-03, FE-TEST-02).
- Do not change `AppIconButton`, the floating Feedback button, `AppPrimaryAction`'s full-width
  layout, button height, radius or text style.

## Definition of done

- [x] Filled, outlined and text buttons have `Space.x4` between the label and each side.
- [x] "Create a project" on the empty Projects list no longer touches its outline, in light, dark
      and outdoor.
- [x] Buttons in dialogs, forms, empty states and footers still fit at 360 dp and 200 percent text.
- [x] Icon buttons and the floating button are pixel-identical to before.
- [x] Light and outdoor share geometry.
- [x] Tests: theme asserts `Space.x4` padding on filled, outlined and text buttons in all three
      themes; outdoor geometry still matches light; a long `AppButton` label at 360 dp and 200
      percent text wraps without overflow.
