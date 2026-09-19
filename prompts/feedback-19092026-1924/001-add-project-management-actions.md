# 001 — Add project management actions

**Feedback:** FBK0000015, FBK0000017 · **Type:** Gap · **Priority:** P2 · **Effort:** M · **Depends on:** —

## Goal
From an open project's home, the operator can see all projects, start a new one, edit its details and
settings, archive it or delete it. From the project list, a new project can always be created, whether or
not projects already exist. Tapping Projects again returns to the list. This works at compact, medium and
expanded widths, in light, dark and outdoor, and at 200 percent text.

## Evidence
- FBK0000015: once a project exists, the reporter finds no way to create another or to switch between
  projects, and asks for a simple, obvious way. `screenshots/FBK0000015.png` shows a project home with
  no project controls. Android, mobile, compact, portrait, system dark, app 1.0.0, route `/projects/<id>`.
- FBK0000017: the reporter sees no obvious way to edit or delete a project. It is the same screenshot.
- Root causes:
  - `frontend/lib/features/projects/presentation/project_list_screen.dart:59-99` renders rows only.
    "Create a project" exists only in the empty state (`:110-129`), so with one project there is no
    create action.
  - `project_home_screen.dart` has `showAppBar: false` and no header actions: `AppPage` (`:27-54`) has no overflow, and `_HomeBody` opens with the name and context text only.
  - `ProjectEditScreen` and `ProjectSettingsScreen` have routes (`frontend/lib/app/router.dart:248-262`)
    but no caller: nothing in `lib/` calls `AppRoutes.projectEdit` or `AppRoutes.projectSettings`.
  - `ProjectDuplicateAction` (`project_duplicate_action.dart`) is built but unused.
  - Re-tapping Projects keeps the branch stack (`frontend/lib/app/nav_shell.dart:122,157` pass
    `shell.goBranch` directly), so the home never gives way to the list.

## Scope
- Change:
  - `project_home_screen.dart`: a header row with the project name and a catalogue `AppOverflowMenu`
    holding All projects, New project, Project details, Project settings, Archive and Delete (and
    Duplicate, per the review). Archive and Delete reuse `ProjectArchiveAction.apply` and
    `ProjectDeleteAction.confirm`, then go to the list.
  - `project_list_screen.dart`: an `AppPrimaryAction` footer, "Create a project", whenever the list has
    loaded. Add Project details to each row's overflow, beside Archive and Delete.
  - `frontend/lib/app/nav_shell.dart`: in `_Bar` and `_Rail`, call
    `shell.goBranch(index, initialLocation: index == shell.currentIndex)`.
  - `frontend/lib/core/copy/copy.dart`: add `projectAllProjects` and `projectNew`; reuse
    `Copy.projectEditTitle`, `Copy.projectSettingsTitle`, `Copy.projectArchive`, `Copy.projectDelete`
    and `Copy.projectsCreate`.
  - Tests, listed in the steps.
- Do not change: the create, edit, settings, archive or delete screens and their confirmations (tasks
  084–087), `CurrentProject` persistence, the launch restore, or the four destinations.

## Rules
- FE-SIMP-01: the list's one primary action is Create; the home keeps Continue capturing as its only
  primary action.
- FE-CONS-01, FE-CONS-05 and FE-CONS-06: `AppOverflowMenu`, `AppPrimaryAction`, `AppListTile` and the
  existing confirmations only.
- FE-CONS-08: reuse the icons already used for these actions (`edit_outlined`, `inventory_2_outlined`,
  `delete_outline`).
- FE-STR-04: feature files cannot import `router.dart`, so keep local path constants, as the file does.
- FE-RESP-03: switching branches or size class keeps in-progress input.
- FE-L10N-01, FE-A11Y-01 and FE-A11Y-02: `Copy` strings, 48 dp, and labels.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 08-projects add-project-management-actions "Add project management actions"`
   (FE-FLOW-08).
2. Add the home header row and its menu, then the list footer and row item.
3. Make a re-tap of the current destination return to its root in the bar and the rail.
4. Tests:
   - `frontend/test/features/projects/presentation/project_home_screen_test.dart`: each menu item reaches
     its route; Archive and Delete land on the list; the menu meets the label and 48 dp matchers.
   - `project_list_screen_test.dart`: Create shows with zero, one and many projects; Project details
     opens `/projects/<id>/edit`.
   - `frontend/test/app/nav_shell_test.dart`: tapping Projects while on a project home shows the list,
     at 400, 800 and 1200 dp.

## Human review
⛔ Stop before step 2 and ask:
- Home menu: All projects, New project, Project details, Project settings, Archive, Delete. Also add
  Duplicate, which is built but unreachable? Recommend yes; it is another way to start a project.
- List Create: (a) an `AppPrimaryAction` footer, or (b) a button in the header row? Recommend (a),
  because it sits in the thumb zone (FE-SIMP-01).
- Re-tapping a destination returns it to its root for all four tabs? Recommend yes, which is the
  platform convention.
Proceed only with an explicit answer. If the answer is "proceed", take every recommendation.

## Acceptance criteria
- [ ] With one or more projects, the list shows "Create a project", and it opens `/projects/new`.
- [ ] From a project home: All projects shows the list; New project opens the create form; Project
      details and Project settings open their screens.
- [ ] Archive or Delete from the home runs the existing confirmation and then shows the list.
- [ ] Opening another row from the list makes it the current project, and capture follows it.
- [ ] Tapping Projects on a project home shows the list, at compact, medium and expanded widths.
- [ ] No clipping at 360 dp, in landscape or at 200 percent text, in light, dark and outdoor.
- [ ] FBK0000015 and FBK0000017 are resolved.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- On an Android phone: create two projects, switch between them, then edit and delete one.
- No goldens change.
