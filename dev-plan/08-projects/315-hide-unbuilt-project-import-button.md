# 315 — Hide the unbuilt project import button

**Phase** 08 · Projects  |  **Depends on** [083](083-project-list.md), [314](314-add-project-management-actions.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The project list never offers a control that does nothing. The import button stays hidden until bundle import exists
(task 222), and its label and the empty-state copy say "Import a project" when it returns.

## Files

- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/core/copy/copy_test.dart`
- `dev-plan/20-data-import/222-import-entry.md`

## Constraints

- An empty state names the next action, and the one offered works (FE-SIMP-11).
- Code keeps the canonical word `bundle`. Only the button's wording changes (FE-CONS-07).
- Labels live in `Copy`; the key name stays, since it names meaning (FE-L10N-01, FE-L10N-02).
- Do not build import here (FE-FLOW-04).
- Do not change `DomainNames.bundle`, bundle code, or any other empty state.

## Definition of done

- [x] The empty Projects list shows "Create a project" and no import control.
- [x] The empty message reads "Create a project to start capturing."
- [x] `Copy.projectsImport` reads "Import a project", and task 222 records where it returns.
- [x] Tests: the empty state shows Create and no import control; tapping Create opens the form; the new copy values
      pass the vocabulary checks.
