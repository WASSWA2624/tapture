# 326 — Add a borderless overflow control

**Phase** 03 · Design system  |  **Depends on** [034](034-app-button.md), [075](../06-app-shell/075-status-line.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`AppOverflowMenu` gains an `outlined` flag that matches `AppIconButton`. The default stays
outlined so every current call site is unchanged. `outlined: false` drops the box, keeps the
48 dp target, and paints a token surface on hover, focus and press. The rest-state glyph stays
full `onSurface` ink on every platform.

## Files

- `frontend/lib/core/widgets/app_overflow_menu.dart`
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`
- `frontend/test/core/widgets/app_overflow_menu_test.dart`
- `frontend/test/design_system/app_overflow_menu/gallery_golden_test.dart`

## Constraints

- Extend the catalogue widget; do not fork a second three-dot control (FE-CONS-01, FE-CONS-02).
- The gallery ships both variants in rest, hover, focus, pressed and disabled (FE-CONS-03).
- Tokens only for hover, focus and press — `surfaceVariant`, never a literal fill (FE-THEME-01,
  FE-THEME-11). Separate by tone, not shadow (FE-THEME-06).
- Outdoor changes contrast, not geometry (FE-THEME-03, FE-THEME-10).
- 48 dp, a required label and tooltip, and a focus indicator that is visible without the border
  (FE-A11Y-01, FE-A11Y-02, FE-A11Y-06).
- Do not change the default, the menu sheet, `showAppOverflowActions`, `AppIconButton`, the
  central `iconButtonTheme`, or any call site. Adopting the flag on the project row is 006.

## Definition of done

- [x] `AppOverflowMenu()` with no extra arguments renders as it does today.
- [x] `AppOverflowMenu(outlined: false)` has no border, stays 48 dp, and opens the same menu.
- [x] Hover, focus and press use `surfaceVariant` in light, dark and outdoor.
- [x] At rest the borderless glyph is full `onSurface` ink and meets contrast in all three themes.
- [x] Both variants appear in the widget gallery in every state.
- [x] Tests: default still paints a border; borderless paints none; both keep the target, label
      and tooltip; both open and select; focus-traversal shows a visible indicator on the
      borderless variant; goldens for both variants in light, dark and outdoor at default and
      200 percent text.
