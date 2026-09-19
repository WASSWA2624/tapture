# 004 — Fix navigation icons and the Capture tab state

**Feedback:** FBK0000016 · **Type:** Defect · **Priority:** P3 · **Effort:** M · **Depends on:** —

## Goal
Navigation uses widely recognised icons: a folder for Projects everywhere a project is meant. Only the
destination that is actually selected looks selected. Capture stays larger than its neighbours but no
longer wears the selected colour when another tab is active. This holds in the bottom bar and the rail,
at compact, medium and expanded widths, in light, dark and outdoor.

## Evidence
- FBK0000016 (second and third parts): the Projects icon is misleading and the app should use familiar
  icons; the Capture tab looks selected when it is not. `screenshots/FBK0000016.png` shows the bottom bar
  with Projects selected and the camera still tinted in the accent colour. Android, mobile, compact,
  portrait, system dark.
- Root causes, in `frontend/lib/app/nav_shell.dart`:
  - Projects uses `Icons.chat_bubble_outline` / `Icons.chat_bubble` (`:295-296`), a chat symbol, and
    Records uses `Icons.forum_outlined` / `Icons.forum` (`:307-308`).
  - `_NavIcon` colours the destination in the accent when `destination.dominant || selected`
    (`:261-263`), so Capture (`dominant: true`) always looks selected.
- Every project empty state uses a folder (`project_list_screen.dart:115`, `project_home_screen.dart:42`,
  `project_edit_screen.dart:53`). The status line's project item uses `Icons.work_outline`
  (`frontend/lib/app/widgets/status_line.dart:73`), so one concept has three icons (FE-CONS-08).
- The icons and the always-accent Capture come from task 073's destination table
  (`dev-plan/06-app-shell/073-nav-shell.md:32-37`). The specification only asks that the centre button
  be "visually dominant" (`app-write-up.md:3219`).

## Scope
- Change:
  - `nav_shell.dart`: Projects becomes `Icons.folder_outlined` / `Icons.folder`. Records changes per the
    review. `_NavIcon` colours by `selected` only; Capture keeps its larger `Space.x8` size.
  - `status_line.dart`: the project overflow item uses `Icons.folder_outlined`.
  - `frontend/test/app/nav_shell_test.dart`: rewrite `_expectCaptureDominant` (`:180-201`) to assert
    size dominance, plus accent colour only when Capture is selected.
  - `dev-plan/06-app-shell/073-nav-shell.md`: update the destination table to match (FE-FLOW-08).
- Do not change: the four destinations, their order or labels, the rail inversion rules, the list pane,
  or Capture's size.

## Rules
- FE-CONS-08 and FE-THEME-08: one icon per concept, from one family, at token sizes.
- FE-A11Y-05 and FE-THEME-05: selection is shown by colour, the filled icon and the bar's indicator.
- FE-SIMP-02: still exactly four destinations.
- FE-THEME-01 and FE-THEME-03: tokens only; outdoor changes contrast, not shape.
- FE-TEST-06: `nav_shell_test` is a feature test, not a phase-01 guardrail; change it together with the
  code.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 06-app-shell fix-navigation-icons-and-capture-state "Fix navigation icons and the Capture tab state"`
   (FE-FLOW-08).
2. Change the icons and the `_NavIcon` colour rule, and the status line icon.
3. Tests in `nav_shell_test.dart` at 400, 800 and 1200 dp:
   - with Projects selected, Capture's icon is larger but uses the unselected ink, not the accent;
   - with Capture selected, it uses the accent and the filled camera;
   - Projects shows `Icons.folder_outlined`, and `Icons.folder` when selected;
   - the dark desktop rail keeps the contrast its tests already assert.
   - `frontend/test/app/widgets/status_line_test.dart`: the project item's icon is the folder.
4. Update task 073's table.

## Human review
⛔ Stop before step 2 and ask:
- Capture's emphasis: keep its larger size and drop the always-on accent? This changes task 073's "primary
  tone" line, but the specification only asks for "visually dominant". Recommend yes.
- Records: replace `forum` (a chat symbol) with `Icons.list_alt_outlined` / `Icons.list_alt`, under the
  reporter's "use globally known icons"? Recommend yes.
Proceed only with an explicit answer. If the answer is "proceed", take both recommendations.

## Acceptance criteria
- [ ] Projects shows a folder in the bar and the rail, and the status line's project item shows the same
      folder.
- [ ] With any tab other than Capture selected, the camera is larger but not accent-coloured.
- [ ] With Capture selected, it is accent-coloured and filled.
- [ ] Light, dark, outdoor and the inverted desktop rail keep 3:1 icon contrast (FE-THEME-10).
- [ ] FBK0000016's second and third parts are resolved. Its first part is 003.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Regenerate with `--update-goldens` only the goldens that draw the bar or the rail, if any, and list
  every file.
