# 324 — Fix the project home count navigation

**Phase** 06 · Application shell  |  **Depends on** [072](072-router-setup.md), [073](073-nav-shell.md), [085](../08-projects/085-project-home.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Tapping Review, Process, Export or Share on the project home opens a list that belongs to the open
project and can be left again by the platform's own way back. Templates, Unprocessed and Export
history live under Settings so that branch still has the settings list beneath them. Old `/queue`,
`/exports` and `/templates` links redirect to the nested paths.

## Files

- `frontend/lib/app/router.dart`
- `frontend/lib/core/widgets/app_page.dart`
- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/project_delete_action.dart`
- `frontend/lib/features/templates/presentation/` local `_templatesRoot` constants
- `frontend/test/app/router_test.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/core/widgets/app_page_test.dart`
- `frontend/test/features/projects/presentation/project_home_screen_test.dart`

## Constraints

- Paths are declared once in `router.dart`; feature files keep matching local constants (FE-STR-02,
  FE-CODE-09).
- A push survives a rail-to-bar change (FE-RESP-03).
- Still four destinations — nesting changes paths, not the menu (FE-SIMP-02).
- Leaving a list discards nothing; the back control is keyboard-reachable (FE-SIMP-09, FE-A11Y-06).
- Reuse `AppPage` and `AppIconButton` — 48 dp, semantic label, tooltip (FE-CONS-01, FE-A11Y-01,
  FE-A11Y-02).
- Placeholder bodies stay placeholders.

## Definition of done

- [x] Each of the four count cards opens a location that names the open project and the filter.
- [x] From each of those lists, the title-bar back control and a pop return to the project home with
      its counts unchanged.
- [x] After opening any of them, the rail and the bottom bar still select Projects.
- [x] Opening Templates or Unprocessed from Settings leaves Settings selected, and tapping Settings
      returns to the settings list rather than a placeholder.
- [x] Old `/queue`, `/exports` and `/templates` links still resolve.
- [x] Tests: `router_test` nested paths, settings-beneath, unknown path, project-scoped divert;
      `project_home_screen_test` card locations, pop, widths and back a11y; `nav_shell_test`
      destination selection.
