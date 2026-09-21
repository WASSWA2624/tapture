# 333 — Shell back and screen title

**Phase** 06 · Application shell  |  **Depends on** [075](075-status-line.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On every route that is not a branch root, the status line is the only header:
a back control, the screen title, and that page's actions. The four roots keep
the wordmark and the status menu.

## Files

- `frontend/lib/app/shell_title.dart`
- `frontend/lib/app/widgets/status_line.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/app/feedback_host.dart`
- `frontend/lib/core/widgets/shell_header_scope.dart`
- `frontend/lib/core/widgets/app_page.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/test/app/widgets/status_line_test.dart`

## Constraints

- One header. Roots stay `/projects`, `/capture`, `/records` and `/more`,
  unless a filter query has drilled in (FE-CONS-01, FE-CONS-10).
- Page title and actions publish through `ShellHeaderScope` in `core/`.
  `core/` does not import a feature (FE-STR-04).
- Titles come from `Copy` or the open project's name (FE-L10N-01).
- Back is a 48 dp `AppIconButton`. The title ellipsises at 200 percent
  (FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- System back is unchanged. The status menu's destinations are unchanged.
- Do not outline the back control. Do not remove the root wordmark.

## Definition of done

- [x] `/projects`, `/capture`, `/records` and `/more` show the wordmark and the
      status menu, and no back control.
- [x] Storage, a filtered Records list, project home and project capture show
      one row: back, one title, and that page's actions. No second title row.
- [x] Back from storage lands on Settings, from a project home on the project
      list, and from project capture on that project.
- [x] The row does not overflow at 200 percent text at 400 dp and 1200 dp.
- [x] Tests cover those routes.
