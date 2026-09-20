# 005 — Show the project count on the Projects destination

**Feedback:** FBK0000006, FBK0000008 · **Type:** Gap · **Priority:** P5 · **Effort:** S · **Depends on:** —

## Goal
The Projects destination carries the number of projects — in the bottom bar on compact, and on the rail
at medium and expanded — so the menu says how much is behind it without being opened. The count is
announced to screen readers, reads correctly in light, dark and outdoor, and neither clips nor overlaps
the label at 200 percent text in either orientation.

## Evidence
- FBK0000006: the reporter asks that "the projects menu item should show the number of projects (all
  projects except deleted one)". `screenshots/FBK0000006.png` shows the rail with a bare Projects icon
  while a project exists.
- FBK0000008: the reporter finds the main menu insufficient and asks that whatever is done for desktop
  be applied to mobile and tablet too. `screenshots/FBK0000008.png` shows the same four-item rail. This
  prompt covers the part of FBK0000008 that overlaps FBK0000006; the rest is an open question in
  `INDEX.md`. Both entries: web, desktop, expanded (1280x585 @1.5x), landscape, light, text scale 1.
- Root cause: `frontend/lib/app/nav_shell.dart:270-284` — `_Destination` carries only `icon`,
  `selectedIcon`, `label`, `dominant` and `hasList`, and `_NavIcon` (`:242-268`) draws a bare `Icon`.
  Neither `_Bar` (`:105-140`) nor `_Rail` (`:142-179`) can show a count, and the shell reads no data.

## Scope
- Change:
  - `frontend/lib/app/nav_shell.dart`: let a destination supply a count, and wrap its icon in Material's
    `Badge` in both `_Bar` and `_Rail`. Read the count from the projects barrel (FE-STR-08) — the shell
    is `lib/app/`, so this import is allowed where `core/` would not be.
  - `frontend/lib/features/projects/presentation/project_list_filter.dart` or the projects providers: a
    count provider derived from the existing watch, so no second query is opened.
  - `frontend/lib/core/copy/copy.dart`: an ICU-plural semantic string for the badge, in the shape
    `Copy.navProjectsCount(n)` (FE-L10N-03 — never assembled by hand).
  - Tests, listed in the steps.
- Do not change: the four destinations, their order, their icons, the dominant Capture sizing, the pane,
  or any other destination's chrome. Capture, Records and Settings get no badge in this prompt.

## Rules
- FE-SIMP-02: four destinations. A count is not a fifth.
- FE-RESP-02: no `MediaQuery` width comparison in the shell; the badge is built the same way in both
  layouts.
- FE-RESP-06 and FE-A11Y-03: nothing clips at 200 percent text; the badge shrinks or caps rather than
  pushing the label out.
- FE-THEME-01, FE-THEME-02 and FE-THEME-10: token colours, defined in all three themes, meeting 4.5:1
  against the badge surface — including on the inverted light-desktop rail
  (`_darkDesktopRail`, `nav_shell.dart:286-293`), where `AppColors.dark` is in force.
- FE-THEME-05 and FE-A11Y-05: the badge is a number, never colour alone.
- FE-A11Y-07: the count is announced when it changes, not left silent.
- FE-L10N-03 and FE-L10N-04: ICU plurals, and `intl` formats the number for the active locale.
- FE-STATE-06: the count is derived from the live watch, never stored.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 06-app-shell show-project-count-on-destination "Show the project count on the Projects destination"`
   (FE-FLOW-08).
2. Add the count provider over the existing watch, and confirm no extra query is opened.
3. Add the badge to `_Bar` and `_Rail` through the destination definition, not at two call sites.
4. Tests:
   - `frontend/test/app/nav_shell_test.dart`: with zero, one, nine and a hundred projects the badge is
     absent, then correct, at 400, 800 and 1200 dp, portrait and landscape; creating and deleting a
     project updates it live; no other destination gains a badge.
   - The badge meets the contrast matcher in light, dark and outdoor, including on the inverted rail.
   - A semantics test that the destination announces its count.
   - Goldens for the bar and the rail at 200 percent text, light, dark and outdoor, with a two-digit
     and a three-digit count.

## Human review
⛔ Stop before step 2 and ask:
- FBK0000006 asks for "all projects except deleted", which includes archived — but the list hides
  archived by default, so a badge of 5 could sit above a list of 3. Count active only, or count active
  plus archived as asked? **Recommendation: count active only**, so the number always matches what the
  destination opens onto; if the answer is "as asked", show the archived share in the badge's semantic
  label so the difference is announced.
- What should a large count show? **Recommendation: cap the display at `99+`** while the semantic label
  keeps the exact number, so the rail does not widen at 200 percent text.

Proceed only with an explicit answer. If the answer is "proceed", do both recommendations.

## Acceptance criteria
- [ ] With no projects the Projects destination shows no badge; with projects it shows the count.
- [ ] The count updates live as projects are created, archived, deleted and restored.
- [ ] The badge appears on the bottom bar at 400 dp and on the rail at 800 and 1200 dp, in both
      orientations.
- [ ] The count is announced to screen readers, with a plural-correct, locale-formatted string.
- [ ] The badge meets 4.5:1 in light, dark and outdoor, including on the inverted light-desktop rail.
- [ ] At 200 percent text nothing clips and no label is pushed out, at all three widths.
- [ ] Capture, Records and Settings are visually unchanged.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Regenerate goldens with `--update-goldens` only for the navigation bar and rail, and list the files
  regenerated.
