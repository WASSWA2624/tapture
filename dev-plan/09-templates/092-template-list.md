# 092 — Template list, blank create and duplicate

**Phase** 09 · Templates  |  **Depends on** [038](../03-design-system/038-app-card.md), [040](../03-design-system/040-app-empty-state.md), [044](../03-design-system/044-app-form-scaffold.md), [088](088-template-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A project's templates listed with field and record counts, and the two ways to make another one: blank from a name,
or a duplicate of an existing template.

## Files

- `frontend/lib/features/templates/presentation/template_list_screen.dart` (new)
- `frontend/lib/features/templates/presentation/template_create_screen.dart` (new)
- `frontend/lib/features/templates/presentation/template_duplicate_action.dart` (new)

## Steps

1. Row actions: open, duplicate, export, and delete only where no record uses the template.
2. Blank creation asks for a name and nothing else, then lands on the field list, so one added field makes the
   template usable.
3. Duplicating copies fields, predefined rows and row aliases. Records stay attached to the original; the copy starts
   with none.

## Constraints

- Rows are `AppListTile`, counts render through the shared formatters, and the delete confirmation names the count
  (FE-CONS-06, FE-CONS-09, FE-SIMP-07).
- The list renders loading, empty, error and offline through `AsyncValueView`, with the empty state offering the
  shipped-library picker as the next action (FE-CONS-04, FE-SIMP-11).

## Definition of done

- [x] A blank template is immediately usable after one added field.
- [x] Duplicating leaves the original's records on the original, and the copy carries its fields, rows and aliases.
- [x] Delete is offered only for a template no record uses.
- [x] Tests: widget tests of `template_list_screen.dart` and `template_create_screen.dart` covering empty and failure states; a test that duplication copies fields, rows and aliases and copies no records.
