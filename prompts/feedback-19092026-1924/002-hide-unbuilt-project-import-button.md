# 002 — Hide the unbuilt project import button

**Feedback:** FBK0000012, FBK0000011 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **Depends on:** 001

## Goal
The project list never offers a control that does nothing. The import button stays hidden until bundle
import exists, and its label and the empty-state copy are ready to say "Import a project" when it
returns. This applies at every width and theme, and at 200 percent text.

## Evidence
- FBK0000012: tapping "Import a bundle" does nothing, and the reporter asks for it to be named "Import a
  project". `screenshots/FBK0000012.png` shows the empty Projects list in dark theme with "Create a
  project" and "Import a bundle". Android, mobile, compact, portrait, route `/projects`.
- FBK0000011 (in part): the reporter finds "Import a bundle" confusing and suggests "Import a project".
  `screenshots/FBK0000011.png` shows the same screen in light theme.
- Root cause: `frontend/lib/features/projects/presentation/project_list_screen.dart:121-125` wires the
  button to `_noop` (`:131`). Importing a bundle as a new project is task 211 (phase 19), with the import
  entry point in task 222, and neither is built. Task 084 fenced it off ("Out of scope: Importing a
  bundle as a new project").
- Copy: `Copy.projectsImport` is "Import a bundle" and `Copy.projectsEmptyMessage` is "Create a project
  or import a bundle to start capturing." (`frontend/lib/core/copy/copy.dart:351-358`).

## Scope
- Change:
  - `project_list_screen.dart`: remove the import `AppButton` and `_noop` from `_empty`.
  - `copy.dart`: set `projectsEmptyMessage` to "Create a project to start capturing.". Change the value
    of `projectsImport` to "Import a project", and document it as reserved for task 222.
  - Tests, listed in the steps.
  - `dev-plan/20-data-import/222-import-entry.md`: add one line saying the Projects empty state shows
    `Copy.projectsImport` again once import works (FE-FLOW-08).
- Do not change: `DomainNames.bundle`, bundle code, or any other empty state.

## Rules
- FE-SIMP-11: an empty state names the next action, and the one offered works.
- FE-CONS-07: code keeps the canonical word `bundle`. Only the button's wording changes, per the review.
- FE-L10N-01 and FE-L10N-02: `Copy` only; the key name stays, since it names meaning.
- FE-FLOW-04: do not build import here.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 08-projects hide-unbuilt-project-import-button "Hide the unbuilt project import button"`
   (FE-FLOW-08).
2. Remove the button and `_noop`, and update the two `Copy` values.
3. Tests:
   - `frontend/test/features/projects/presentation/project_list_screen_test.dart`: the empty state shows
     Create and no import control; tapping Create opens the form.
   - `frontend/test/core/copy/copy_test.dart`: the new values pass the vocabulary checks.
4. Add the note to task 222.

## Human review
⛔ Stop before step 2 and ask:
- (a) hide the button until task 222 ships, (b) show it disabled with "Available after bundle import
  ships", or (c) leave it as it is? Recommend (a), because a dead control is worse than none
  (FE-SIMP-11).
- Say "Import a project" on the button, while code keeps `bundle` (FE-CONS-07)? Recommend yes; a bundle
  is a project packaged for another device.
Proceed only with an explicit answer. If the answer is "proceed", do (a) and rename.

## Acceptance criteria
- [ ] The empty Projects list shows "Create a project" and no import control, in light, dark and outdoor.
- [ ] The empty message reads "Create a project to start capturing." and does not clip at 360 dp or
      200 percent text.
- [ ] `Copy.projectsImport` reads "Import a project", and task 222 records where it returns.
- [ ] FBK0000012 is resolved. For FBK0000011, the label part is resolved here; the button padding is
      005 and the checkbox is 007.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- No goldens change.
