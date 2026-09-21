# 334 — Resolve projects shell feedback

**Phase** 06 · Application shell  |  **Depends on** [325](325-show-projects-in-list-pane.md), [328](328-show-project-count-on-destination.md), [072](072-router-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Clip the expanded project list pane, space title-row actions from overflow,
keep one Create a project control, remove the Projects destination count,
and restore the last internal route on launch.

## Files

- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/app/router.dart`
- `frontend/lib/app/widgets/status_line.dart`
- `frontend/lib/core/widgets/app_list_tile.dart`
- `frontend/lib/core/widgets/app_page.dart`
- `frontend/lib/features/projects/presentation/project_list_actions.dart`
- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/features/settings/domain/setting_keys.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/app/router_test.dart`
- `frontend/test/core/widgets/app_page_test.dart`
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`

## Constraints

- One `AppListTile`. The pane stays 280 dp (FE-CONS-06, FE-RESP-04).
- One primary create control (FE-SIMP-01). Compact and medium use the footer;
  expanded uses the pane button when rows exist and the empty-state action
  when they do not.
- Restore only a relative internal path, never `/lock` (FE-SEC-06).
- `Copy` for new strings. Tests travel with the change (FE-L10N-01, FE-TEST-01).

## Definition of done

- [x] Expanded project rows, dividers and more controls stay inside the pane.
- [x] Compact and medium lists still open a project on tap and are not forced
      to 280 dp.
- [x] `Space.x2` sits between a page action and its overflow menu.
- [x] Each width shows `Copy.projectsCreate` once, and that control opens
      `/projects/new`.
- [x] Projects shows no numeric badge; its spoken name is Projects.
- [x] A stored internal route is the first location; `https://` and `/lock`
      open `/projects`.
- [x] Tests cover those cases.
