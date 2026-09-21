# 332 — Borderless overflow menus

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three-dot More control has no box unless a caller asks for one. Title bars,
the status line, project home and the expanded pane use that default. The gallery
keeps an explicit outlined specimen, and outdoor outline weight stays `Space.x0`.

## Files

- `frontend/lib/core/widgets/app_overflow_menu.dart`
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`
- `frontend/test/core/widgets/app_overflow_menu_test.dart`
- `frontend/test/design_system/app_overflow_menu/gallery_golden_test.dart`

## Constraints

- Change the shared menu once (FE-CONS-01). Both variants stay in the gallery
  (FE-CONS-03).
- No new colour or width. Outdoor keeps the heavier outline (FE-THEME-01,
  FE-THEME-03, FE-THEME-10).
- The control stays 48 dp, named, and shows a token fill on hover, focus and
  press (FE-A11Y-01, FE-A11Y-02, FE-A11Y-06).
- Do not outline `StatusLine`, `AppPage`, `ProjectHomeScreen` or
  `ProjectListActions.paneToolbar`. Do not change `AppIconButton`, divider
  thickness, menu shape or menu contents.

## Definition of done

- [x] A default `AppOverflowMenu` has no border and still opens its labelled
      actions, at 48 dp, in light, dark and outdoor.
- [x] `outlined: true` still draws the theme outline, at `Space.x0 / 2` in light
      and dark and `Space.x0` outdoors.
- [x] Status line, page bar, project home and the expanded pane toolbar are
      borderless. List-row menus stay borderless.
- [x] Tests: default has no side; outlined width in all three themes; open and
      select for both variants; 200 percent text at 400, 800 and 1200.
- [x] Goldens regenerated only where a default More control lost its box.
