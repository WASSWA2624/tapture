# 001 — Remove overflow menu border

**Feedback:** FBK0000020, FBK0000006 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **Depends on:** none

## Goal
The three-dot More control has no box around it, on every screen that uses it, in light, dark and outdoor, at compact, medium and expanded widths, both orientations, and at 200 percent text.

## Evidence
- FBK0000020: remove the border on the More button, and reduce how heavy borders look. `prompts/TAPTURE-21092026-2146/screenshots/FBK0000020.png` and `FBK0000020-2.png` show the Projects list with a boxed overflow control in the title strip. Android, compact, portrait, dark.
- FBK0000006: remove the border on the three-dot More controls. `prompts/TAPTURE-21092026-2151/screenshots/FBK0000006.png` shows boxed overflow controls on the status strip, the list pane and the project home. Web, expanded, landscape, dark.
- Root cause: `AppOverflowMenu.outlined` defaults to true (`frontend/lib/core/widgets/app_overflow_menu.dart:19`), so the control picks up `iconButtonTheme`'s outline (`frontend/lib/app/theme/app_theme.dart:90`). List rows already pass `outlined: false` (`frontend/lib/features/projects/presentation/project_list_view.dart:73`). Stroke weight is already the hairline `Space.x0 / 2` except outdoor, which uses `Space.x0` (`frontend/lib/app/theme/app_theme.dart:378`). Do not thin that stroke.

## Scope
- Reach: every platform and size class that renders `AppOverflowMenu` (status line, `AppPage`, project home, expanded pane toolbar, list rows). No surface excluded.
- Change: `AppOverflowMenu` default, the gallery specimen that must stay outlined, and call sites that should keep a border (none of the reported ones).
- Do not change: `AppIconButton` outlines (the add control), `Divider` thickness, outdoor outline weight, menu shape, or menu contents.

## Rules
- FE-CONS-01, FE-CONS-03: change the shared menu, and keep both variants in the gallery.
- FE-THEME-01, FE-THEME-03, FE-THEME-10: no new colour or width; outdoor keeps its heavier outline.
- FE-A11Y-01, FE-A11Y-02, FE-A11Y-06: target size, name and hover or focus fill stay.
- FE-TEST-01, FE-TEST-02: widget test plus goldens.

## Steps
1. Record the work: extend the task that owns `AppOverflowMenu`, or `cd frontend && dart run tool/new_task.dart 23-hardening borderless-overflow-menus "Borderless overflow menus"` (FE-FLOW-08).
2. Default `AppOverflowMenu.outlined` to false so the borderless style in `_borderlessStyle` is what callers get.
3. In `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`, pass `outlined: true` on one specimen so the outlined variant stays in the gallery. Leave the borderless specimen explicit.
4. Do not pass `outlined: true` from `StatusLine`, `AppPage`, `ProjectHomeScreen` or `ProjectListActions.paneToolbar`.
5. Update `frontend/test/core/widgets/app_overflow_menu_test.dart` so the default construct has no side, and an explicit `outlined: true` still draws one.
6. Regenerate only the overflow-menu goldens whose default specimen lost its box.

## Acceptance criteria
- [ ] A default `AppOverflowMenu` has no border and still opens its labelled actions, at 48dp, in light, dark and outdoor.
- [ ] An `outlined: true` menu still draws the theme outline, including the outdoor weight.
- [ ] Status line, page bar, project home and the expanded pane toolbar show a borderless more control. List-row menus stay borderless.
- [ ] Add buttons, dividers and outdoor field outlines are unchanged.
- [ ] FBK0000020's border request and FBK0000006's border request are resolved. Numbering and back navigation are not this prompt.

## Verification
- `cd frontend && dart run tool/verify.dart --fast`, then `dart run tool/verify.dart`.
- `--update-goldens` only for the overflow-menu goldens this prompt changes. List the files.
