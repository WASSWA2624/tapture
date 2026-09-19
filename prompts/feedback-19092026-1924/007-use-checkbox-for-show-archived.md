# 007 — Use a checkbox for Show archived

**Feedback:** FBK0000011 · **Type:** Improvement · **Priority:** P5 · **Effort:** S · **Depends on:** 001, 002

## Goal
The Projects list filter "Show archived" is a two-state checkbox with its label, not a switch. This holds
at compact, medium and expanded widths, in light, dark and outdoor, and at 200 percent text.

## Evidence
- FBK0000011 (in part): the reporter asks for the "Show archived" toggle to become a two-state checkbox.
  `screenshots/FBK0000011.png` shows the switch at the top of an empty Projects list, light theme, with
  its label flush against the left edge. Android, mobile, compact, portrait.
- Code: `frontend/lib/features/projects/presentation/project_list_screen.dart:46-51` uses
  `AppSwitchTile(...)`. The catalogue already has `AppSwitchTile.checkbox`
  (`frontend/lib/core/widgets/fields/app_switch_tile.dart:22-23`), which the feedback form uses with
  `controlFirst: true`.

## Scope
- Change:
  - `project_list_screen.dart`: use `AppSwitchTile.checkbox(title: Copy.projectShowArchived,
    value: showArchived, dense: true, controlFirst: true, onChanged: …)`, with the same provider. The
    page has `inset: false`, so if the tile still renders flush with the screen edge (as in the
    screenshot), give it the horizontal padding `AppListTile` rows use.
  - `frontend/test/features/projects/presentation/project_list_screen_test.dart`: switch the finder to
    `Checkbox`, and keep the archived-filter assertions.
- Do not change: `projectListShowArchivedProvider`, the filter logic, the copy, or other switches in the
  app (Stay offline, settings).

## Rules
- FE-CONS-01: reuse `AppSwitchTile.checkbox`, and build no new control.
- FE-CONS-10: a tap on the row or the box toggles it.
- FE-A11Y-01, FE-A11Y-02 and FE-A11Y-05: 48 dp, labelled, and the state is shown by the tick as well as
  colour.
- FE-L10N-05: the control sits at the start in both text directions.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 08-projects use-checkbox-for-show-archived "Use a checkbox for Show archived"`
   (FE-FLOW-08).
2. Swap the control.
3. Tests: ticking shows archived rows and unticking hides them; the tile passes the 48 dp and label
   matchers; no overflow at 360 dp and 200 percent text.

## Acceptance criteria
- [ ] Projects shows a checkbox labelled "Show archived", unticked by default.
- [ ] Ticking it lists archived projects, and unticking hides them again.
- [ ] The label no longer sits flush against the screen edge, and the row is inset like other tiles.
- [ ] It looks right in light, dark and outdoor, at every width and at 200 percent text.
- [ ] FBK0000011 is resolved together with 002 (label) and 005 (padding).

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- No goldens change.
