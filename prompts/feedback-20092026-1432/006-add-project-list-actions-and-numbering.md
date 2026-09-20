# 006 — Add project list actions and numbering

**Feedback:** FBK0000006 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **Depends on:** 002, 003, 004

## Goal
The project list carries its own actions — create, filter and a list-level more menu holding Show
archived — and each row is numbered and carries a borderless three-dot menu offering Rename, Pin,
Archive and Delete. On expanded the actions sit in the list pane's header; on compact and medium, which
have no pane, the same actions sit in the project list screen's title bar, so no platform loses one.
"Show archived" leaves the body. Correct in light, dark and outdoor, in both orientations, and at 200
percent text.

## Evidence
- FBK0000006: the reporter asks for a create button, a filter button and a three-dot more button holding
  a projects context menu; for "Show archived" to move out of the project screen area into that menu;
  for the list to be numbered; and for each row to carry a three-dot more button with no border but
  still noticeable, offering archive, pin, rename, open with and delete.
  `screenshots/FBK0000006.png` shows "Show archived" as a checkbox above the body list, and the pane
  with no actions at all; `-2` shows today's row menu — Project details, Archive, Delete project. Web,
  desktop, expanded (1280x585 @1.5x), landscape, light, text scale 1.
- Current code:
  - The pane has no actions: `frontend/lib/app/nav_shell.dart:181-240` builds a search field and its
    content, nothing else.
  - "Show archived" is in the body:
    `frontend/lib/features/projects/presentation/project_list_screen.dart:53-62`.
  - Rows are unnumbered and their menu is Project details, Archive, Delete (`:73-114`); the menu is
    drawn as an outlined box because `iconButtonTheme` supplies `side: outline`
    (`frontend/lib/app/theme/app_theme.dart:90-102`).
  - The filter state is `projectListShowArchivedProvider`
    (`frontend/lib/features/projects/presentation/project_list_filter.dart:15-19`).

## Scope
- Change:
  - `frontend/lib/app/nav_shell.dart`: a pane header row holding the create action, a filter control and
    an `AppOverflowMenu`, above the search field.
  - `project_list_screen.dart`: the same three actions through `AppPage.actions` and `AppPage.overflow`
    at compact and medium; remove the body's `AppSwitchTile.checkbox`.
  - `project_list_view.dart` (from 002): a leading position number on each row, and
    `AppOverflowMenu(outlined: false)` (from 003) with Rename, Pin/Unpin (from 004), Archive/Unarchive
    and Delete.
  - `frontend/lib/features/projects/presentation/project_rename_action.dart` (new): a one-field rename
    using the shared dialog API, beside the existing `project_archive_action.dart` and
    `project_delete_action.dart`.
  - `frontend/lib/core/copy/copy.dart`: `projectPin`, `projectUnpin`, `projectRename` and the filter
    control's label and tooltip.
  - Tests, listed in the steps.
- Do not change: `ProjectEditScreen`, `ProjectSettingsScreen`, the create and duplicate flows, the
  archive and delete confirmations, the row's subtitle and counts, the four destinations, or the pin
  storage and ordering that 004 delivers. "Open with" is 007's work; do not add it here.

## Rules
- FE-CONS-01, FE-CONS-05 and FE-CONS-06: `AppOverflowMenu`, `AppIconButton`, `AppPrimaryAction`,
  `AppListTile` and the one dialog API only; a destructive action pairs a confirm with an undo.
- FE-CONS-07 and FE-CONS-08: one vocabulary and one icon per concept — reuse `edit_outlined`,
  `inventory_2_outlined` and `delete_outline`, and fix one icon each for pin and filter.
- FE-CONS-09: the row number is formatted by the shared formatter, in the active locale.
- FE-SIMP-01: one primary action — create is the pane header's only filled control.
- FE-SIMP-07: the rename dialog has a safe default and a way out; Delete still names the count.
- FE-A11Y-01, FE-A11Y-02 and FE-A11Y-06: 48 dp, labels and tooltips on every icon control, and
  traversal order matching visual order across the new header.
- FE-L10N-01, FE-L10N-03 and FE-L10N-05: `Copy` strings, no assembled sentences, `start`/`end` so the
  number leads correctly in RTL.
- FE-RESP-02, FE-RESP-04 and FE-RESP-06: size class from `context.sizeClass`; the header wraps rather
  than clipping at 200 percent text.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 08-projects add-project-list-actions "Add project list actions and numbering"`
   (FE-FLOW-08).
2. Add the pane header and the compact and medium title-bar equivalents, both reading the same actions
   list so the two layouts cannot drift.
3. Move "Show archived" into that menu and delete it from the body.
4. Add the row number and swap the row menu to the borderless variant.
5. Add Rename and Pin/Unpin to the row menu, reusing `ProjectArchiveAction` and `ProjectDeleteAction`
   patterns for the new action file.
6. Tests:
   - `frontend/test/app/nav_shell_test.dart`: at 1200 dp the pane header shows create, filter and the
     more menu; the menu toggles Show archived and the pane list responds.
   - `frontend/test/features/projects/presentation/project_list_screen_test.dart`: at 400 and 800 dp the
     same three actions are reachable from the title bar; the body no longer contains the checkbox;
     rows are numbered 1..n in the order shown, and renumber when the filter or search changes.
   - `project_list_view_test.dart`: the row menu offers Rename, Pin, Archive and Delete; Rename saves
     and cancels; Pin moves the row to the top and the number follows; the menu has no border and still
     meets the 48 dp, label and tooltip matchers.
   - Goldens for the pane header and a numbered pinned row, light, dark and outdoor, at default and 200
     percent text.

## Human review
⛔ Stop before step 3 and ask:
- "Show archived" is a control people already use. Moving it into a menu hides it behind a tap. Move it
  as asked, or keep it visible on compact where there is no pane header? **Recommendation: move it as
  asked at every width**, so one mental model holds, with the menu item showing its on/off state.
- Should the row number be the position in the list as currently filtered and sorted, or a stable
  per-project number that never changes? **Recommendation: position in the current list**, which is what
  a numbered list means and what pinning implies; a stable identifier would be a new stored field and a
  separate task.
- What should the filter button open, given Show archived is the only filter today? **Recommendation:
  ship the filter control disabled-with-tooltip only if a second filter exists; otherwise leave it out
  of this prompt** and let Show archived live in the more menu, rather than adding a control with one
  item in it.

Proceed only with an explicit answer. If the answer is "proceed", do all three recommendations.

## Acceptance criteria
- [ ] At 1200 dp the pane header offers create and the more menu above the search field.
- [ ] At 400 and 800 dp the same actions are reachable from the project list screen's title bar.
- [ ] "Show archived" appears only in that menu, reflects its state, and still filters the list.
- [ ] Rows are numbered from 1 in the order displayed, renumbering when search, filter or pinning changes.
- [ ] Each row's three-dot menu has no border, is visibly hoverable and focusable, and offers Rename,
      Pin or Unpin, Archive or Unarchive, and Delete.
- [ ] Rename saves a new name without moving the project folder, and cancels cleanly.
- [ ] Pin moves the row to the top of the list and persists across a restart.
- [ ] Every new control meets the 48 dp, label, tooltip and contrast matchers in light, dark and outdoor.
- [ ] Nothing clips at 200 percent text at 400, 800 and 1200 dp, in both orientations.
- [ ] FBK0000006's actions, numbering, row-menu and Show-archived parts are resolved; "open with" is 007.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Regenerate goldens with `--update-goldens` only for the navigation pane and the project list, and list
  the files regenerated.
