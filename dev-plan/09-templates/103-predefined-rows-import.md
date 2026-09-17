# 103 — Predefined rows, aliases and the capture checklist

**Phase** 09 · Templates  |  **Depends on** [039](../03-design-system/039-app-status-pill.md), [053](../04-data-layer/053-templates-table.md), [102](102-xlsx-mapping-screen.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Existing spreadsheet rows read in as the checklist an operator works through, the per-row aliases that teach the
matcher local names, and the progress view that shows what has been found and what is still missing.

## Files

- `frontend/lib/features/templates/data/predefined_rows_import.dart` (new)
- `frontend/lib/features/templates/presentation/row_aliases_screen.dart` (new)
- `frontend/lib/features/templates/presentation/checklist_screen.dart` (new)

## Steps

1. Map the identifier and label columns, and keep the original spreadsheet row number on every row for write-back.
2. Add aliases per row, and import aliases in bulk from a chosen column.
3. Group the checklist by context, show "Found 12 of 40" per group, and start a capture for a row when it is tapped.

## Constraints

- Found and not-found render through `AppStatusPill` with a shape as well as a colour (FE-CONS-06, FE-THEME-05).
- The checklist is virtualised; a forty-row and a four-thousand-row template scroll the same (FE-PERF-03).

## Definition of done

- [ ] Rows import with their spreadsheet positions preserved, so a later export writes back to the right line.
- [ ] "BP machine" reliably matches "Blood Pressure Machine".
- [ ] The operator can see what is still missing in the current room.
- [ ] Tests: repository tests for `predefined_rows_import.dart` against an in-memory database, plus the fake later tests use; widget tests of `row_aliases_screen.dart` and `checklist_screen.dart` covering empty and failure states.
