# 109 — Edit a dataset row, and add one from capture

**Phase** 10 · Reference data  |  **Depends on** [044](../03-design-system/044-app-form-scaffold.md), [108](108-dataset-list.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

In-place correction of a reference row, and a sheet that adds a missing supplier or asset from inside capture without
leaving it. Neither changes a record already prefilled from the dataset.

## Files

- `frontend/lib/features/reference/presentation/dataset_row_edit_screen.dart` (new)
- `frontend/lib/features/reference/presentation/dataset_add_row_sheet.dart` (new)

## Steps

1. Record every edit in the audit log with the previous value.
2. Do not retroactively touch records already prefilled from the row; the prefilled value stays as captured.
3. A row added from capture is flagged `addedOnDevice`, and is immediately visible to the lookup that failed.
4. The add sheet asks for the key column and the columns the current lookup binding fills, nothing more.

## Constraints

- Every edit and addition writes an audit entry; the trail is not optional (FE-SEC-09).
- The add sheet is a bottom sheet from the shared API, dismissible without losing the typed values
  (FE-CONS-05, FE-SIMP-09).

## Definition of done

- [ ] Fixing a supplier's phone number does not silently rewrite history.
- [ ] The new row is immediately available to the lookup that failed, without leaving capture.
- [ ] Tests: widget tests of `dataset_row_edit_screen.dart` and `dataset_add_row_sheet.dart` covering empty and failure states; a test that an already-prefilled record keeps its captured value after its source row changes.
