# 314 — Add project management actions

**Phase** 08 · Projects  |  **Depends on** [073](../06-app-shell/073-nav-shell.md), [083](083-project-list.md), [084](084-project-create.md), [085](085-project-home.md), [086](086-project-edit.md), [087](087-project-archive.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

From an open project's home, the operator can see all projects, start a new one, edit its details and settings,
archive it, delete it, or duplicate it. From the project list, a new project can always be created, whether or not
projects already exist. Tapping the current destination again returns that branch to its root.

## Files

- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/features/projects/presentation/project_duplicate_action.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/features/projects/presentation/project_home_screen_test.dart`
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/core/copy/copy_test.dart`

## Steps

1. Add the home header row and its catalogue overflow: All projects, New project, Duplicate, Project details, Project
   settings, Archive and Delete. Archive and Delete reuse `ProjectArchiveAction.apply` and `ProjectDeleteAction.confirm`,
   then go to the list.
2. Add an `AppPrimaryAction` footer, "Create a project", whenever the list has loaded. Add Project details to each row's
   overflow, beside Archive and Delete.
3. In `_Bar` and `_Rail`, call `shell.goBranch(index, initialLocation: index == shell.currentIndex)`.

## Constraints

- The list's one primary action is Create; the home keeps Continue capturing as its only primary action (FE-SIMP-01).
- `AppOverflowMenu`, `AppPrimaryAction`, `AppListTile` and the existing confirmations only (FE-CONS-01, FE-CONS-05,
  FE-CONS-06).
- Reuse the icons already used for these actions (`edit_outlined`, `inventory_2_outlined`, `delete_outline`)
  (FE-CONS-08).
- Feature files cannot import `router.dart`, so keep local path constants (FE-STR-04).
- Switching branches or size class keeps in-progress input (FE-RESP-03).
- `Copy` strings, 48 dp, and labels (FE-L10N-01, FE-A11Y-01, FE-A11Y-02).
- Do not change the create, edit, settings, archive or delete screens and their confirmations, `CurrentProject`
  persistence, the launch restore, or the four destinations.

## Definition of done

- [x] With one or more projects, the list shows "Create a project", and it opens `/projects/new`.
- [x] From a project home: All projects shows the list; New project opens the create form; Project details and Project
      settings open their screens.
- [x] Archive or Delete from the home runs the existing confirmation and then shows the list.
- [x] Opening another row from the list makes it the current project, and capture follows it.
- [x] Tapping Projects on a project home shows the list, at compact, medium and expanded widths.
- [x] Tests: each home menu item reaches its route; Archive and Delete land on the list; the menu meets the label and
      48 dp matchers; Create shows with zero, one and many projects; Project details opens `/projects/<id>/edit`; tapping
      Projects while on a project home shows the list at 400, 800 and 1200 dp.
