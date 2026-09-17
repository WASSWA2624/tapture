# 108 — Dataset list and row browser

**Phase** 10 · Reference data  |  **Depends on** [035](../03-design-system/035-app-text-field.md), [040](../03-design-system/040-app-empty-state.md), [105](105-dataset-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The list of a project's datasets with row count, source and import date, and the paged, searchable table of rows
behind each one.

## Files

- `frontend/lib/features/reference/presentation/dataset_list_screen.dart` (new)
- `frontend/lib/features/reference/presentation/dataset_browser_screen.dart` (new)

## Steps

1. List rows as `AppListTile` with row count, source and import date through the shared formatters.
2. Browse rows in a virtualised, paged list; search filters on the key column and the visible columns.
3. On a narrow screen let the user choose which columns show, defaulting to the key column plus the first two.

## Constraints

- The browser is virtualised and paged; it never holds a whole dataset in memory (FE-PERF-03, FE-PERF-09).
- Both screens render loading, empty, error and offline through `AsyncValueView`, and the empty list offers import as
  its next action (FE-CONS-04, FE-SIMP-11).

## Definition of done

- [ ] Ten thousand rows scroll smoothly, with a measurement behind the claim (FE-TEST-09).
- [ ] Search over a ten-thousand-row dataset returns without a visible pause.
- [ ] Tests: widget tests of `dataset_list_screen.dart` and `dataset_browser_screen.dart` covering empty and failure states; a scroll and search measurement over a ten-thousand-row fixture.
