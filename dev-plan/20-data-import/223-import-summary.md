# 223 — Import summary

**Phase** 20 · Data import  |  **Depends on** [038](../03-design-system/038-app-card.md), [221](221-import-records-create.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

What an import actually did: created, updated, skipped and failed with a reason per row, the skipped and failed rows
exportable as a list, and a retry that re-runs only the failures.

## Files

- `frontend/lib/features/import/presentation/import_summary_screen.dart` (new)

## Steps

1. Group rows by outcome, each row identified by its spreadsheet row number.
2. Export the skipped and failed rows as a file the operator can correct and re-import.
3. Retry re-runs only the failed rows through the same mapping, without duplicating the successful ones.

## Constraints

- Plain language for every reason: a validation message names the field and what was expected (FE-SIMP-10).

## Definition of done

- [ ] Every skipped or failed row is explained with its row number and reason, and the set is exportable as a list.
- [ ] Retrying failures creates no duplicate of an already imported row.
- [ ] Tests: widget test of `import_summary_screen.dart` over a mixed-outcome result, an all-successful result and the four states, asserting retry re-runs only failures.
