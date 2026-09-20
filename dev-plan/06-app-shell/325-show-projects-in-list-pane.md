# 325 — Show the project list in the expanded list pane

**Phase** 06 · Application shell  |  **Depends on** [073](073-nav-shell.md), [083](../08-projects/083-project-list.md), [085](../08-projects/085-project-home.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On expanded widths the list pane lists projects under its search bar, the search bar filters them
by name, and the pane no longer repeats the destination name as a heading. The body stops repeating
that list and shows the open project's home; "Create a project" stays in the body only while there
are no projects. Compact and medium keep the list and the footer in the body.

## Files

- `frontend/lib/features/projects/presentation/project_list_view.dart` (new)
- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/features/projects/presentation/project_list_filter.dart`
- `frontend/lib/features/projects/projects.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/app/nav_pane_golden_test.dart` (new)
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/features/projects/presentation/project_list_filter_test.dart` (new)

## Constraints

- One `ProjectListView` in the pane and on the screen (FE-CONS-02). Rows stay `AppListTile`
  (FE-CONS-06).
- The pane renders loading, empty, error and offline through `AsyncValueView` (FE-CONS-04).
- `core/` never imports `features/`; the pane is wired in `lib/app/` through the feature barrel
  (FE-STR-04, FE-STR-08).
- Size class comes from `context.sizeClass` (FE-RESP-02). A width change keeps the search text and
  the open project (FE-RESP-03).
- Search matches the project name only, case-insensitive and accent-folded, with no new packages.

## Definition of done

- [x] At 1200 dp the pane lists every non-deleted, non-archived project under its search bar, with
      no heading above the search bar.
- [x] Typing in the pane search narrows the list; no match shows an empty state offering
      "Create a project".
- [x] At 1200 dp with at least one project, the body shows the open project and no second copy of
      the list.
- [x] At 1200 dp with no projects, the body shows "Create a project".
- [x] At 400 and 800 dp the list and "Create a project" stay in the body.
- [x] Changing width between 400 and 1200 dp loses neither the typed search nor the open project.
- [x] Tests: pane list, search, clear, no-match, heading gone, Records empty; body create-button
      widths; search and open project across 400↔1200; pane goldens in light, dark and outdoor,
      empty and with three projects.
