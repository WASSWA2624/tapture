# 009 — Clip project list pane

**Feedback:** FBK0000006 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **Depends on:** none

## Goal
On an expanded window, each project row stays inside the list pane. Its divider and trailing menu do not paint into the detail pane. Compact and medium, which have no list pane, keep the same row, fully tappable.

## Evidence
- FBK0000006: the project list under the search field is poorly contained, and rows overflow into the detail area. `prompts/TAPTURE-21092026-2151/screenshots/FBK0000006.png` shows the expanded pane (create, more, search, a numbered row) beside the project home. Web, expanded, landscape, dark. The count, borders and back control are prompts 005, 001 and 002.
- Root cause: the pane is a `SizedBox(width: Sizes.listPane)` with no clip (`frontend/lib/app/nav_shell.dart:91`). `AppListTile` is a `Row` plus a full-bleed `Divider` (`frontend/lib/core/widgets/app_list_tile.dart:71`, `:133`). A row that exceeds 280dp paints into the neighbouring `Expanded` detail.

## Scope
- Reach: expanded width, both orientations, light, dark and outdoor, text scale 1 and 2, every platform that shows the pane. Medium and compact have no pane (`NavShell` sets `pane: false`); the shared row must still layout there, so do not clip those widths to 280dp.
- Change: the pane in `frontend/lib/app/nav_shell.dart`, and `AppListTile` only if the row can exceed its parent's max width.
- Do not change: pane width (`Sizes.listPane`), search, numbering, row actions, or the detail home.

## Rules
- FE-RESP-04, FE-RESP-05, FE-RESP-07, FE-RESP-10: the pane stays 280; the detail keeps the rest; test both orientations and the width matrix.
- FE-CONS-06: one `AppListTile`, not a second projects row.
- FE-A11Y-01, FE-A11Y-03: the trailing menu stays a 48dp target; title and subtitle ellipsize instead of overflowing at 200 percent text.
- FE-THEME-01: the existing hairline stays the pane edge.
- FE-TEST-01, FE-TEST-02.

## Steps
1. Record the work: extend task 325's area, or `cd frontend && dart run tool/new_task.dart 06-app-shell clip-project-list-pane "Clip the project list pane"` (FE-FLOW-08).
2. Clip the pane (`ClipRect` or `clipBehavior: Clip.hardEdge` on the pane `Material`). Keep `BorderDirectional` as the edge against the detail.
3. Give `AppListTile`'s title and subtitle `overflow: TextOverflow.ellipsis` (already set) inside a row that cannot exceed the incoming max width. The trailing menu stays inside that width.
4. In `frontend/test/app/nav_shell_test.dart`, at 1200dp, the project row's right edge is within the pane's right edge, in landscape and at text scale 2. At 400dp the row is not forced to 280.

## Acceptance criteria
- [ ] At expanded width, the numbered project row, its divider and its more control are entirely inside the list pane, in both orientations, light, dark and outdoor, at text scales 1 and 2.
- [ ] The hairline between pane and detail is unbroken across the row.
- [ ] Compact and medium project lists still show the full row and open the project on tap.
- [ ] The overflow sentence of FBK0000006 is resolved.

## Verification
- `cd frontend && dart run tool/verify.dart --fast`, then `dart run tool/verify.dart`.
- `--update-goldens` only for an expanded projects-pane golden this clip changes. List the files.
