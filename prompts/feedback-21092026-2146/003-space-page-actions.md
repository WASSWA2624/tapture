# 003 — Space page actions

**Feedback:** FBK0000022, FBK0000023 · **Type:** Defect · **Priority:** P4 · **Effort:** S · **Depends on:** none

## Goal
When a page bar or the expanded projects pane shows an action beside the more control, those controls are separated by `Space.x2`. They no longer share an edge. All platforms, all three widths, both orientations, light, dark and outdoor, 200 percent text.

## Evidence
- FBK0000023: the create control and the more control need space between them. `prompts/TAPTURE-21092026-2146/screenshots/FBK0000023.png` shows them adjacent in the Projects title row. Android, compact, portrait, dark.
- FBK0000022: the Projects layout is hard to use. The same screenshot pair shows that title row. The duplicate create button is prompt 004; the nav count is prompt 005.
- Root cause: `AppPage` places `actions` and `AppOverflowMenu` in one list with no gap (`frontend/lib/core/widgets/app_page.dart:85`). `ProjectListActions.paneToolbar` already uses `Wrap` `spacing: Space.x2` (`frontend/lib/features/projects/presentation/project_list_actions.dart:60`).

## Scope
- Reach: every `AppPage` that has both bar actions and an overflow menu, and the expanded pane toolbar. No platform excluded.
- Change: `AppPage` action row. Confirm the pane toolbar gap; do not add a second, different gap.
- Do not change: which actions exist, labels, the footer Create a project button, or nav badges.

## Rules
- FE-THEME-01, FE-CODE-09: `Space.x2` only.
- FE-CONS-01: fix `AppPage` once, not each screen.
- FE-A11Y-01, FE-A11Y-03, FE-RESP-10: 48dp targets survive the gap at 200 percent text.
- FE-TEST-01, FE-TEST-02.

## Steps
1. Record the work under `06-app-shell`, or `cd frontend && dart run tool/new_task.dart 06-app-shell space-page-actions "Space page bar actions"` (FE-FLOW-08).
2. In `AppPage`, when `actions` is non-empty and `overflow` is non-empty, insert `SizedBox(width: Space.x2)` before the overflow menu.
3. Leave `ProjectListActions.paneToolbar` on `Space.x2`. If a compact layout still builds that toolbar, it must use the same token.
4. Widget test: a page with one icon action and an overflow menu lays the menu's left edge at least `Space.x2` to the right of the action, on a 400dp and a 1200dp surface, at text scale 2.

## Acceptance criteria
- [ ] Projects on compact shows a visible gap of `Space.x2` between the add control and the more control, in light, dark and outdoor.
- [ ] The expanded pane toolbar gap is `Space.x2` and does not wrap the two controls onto two lines at the default text scale inside `Sizes.listPane`.
- [ ] A page with only an overflow menu has no leading gap.
- [ ] FBK0000023 is resolved. FBK0000022's remaining duplicate-create part is prompt 004.

## Verification
- `cd frontend && dart run tool/verify.dart --fast`, then `dart run tool/verify.dart`.
- `--update-goldens` only if a projects-list golden includes this gap. List the files.
