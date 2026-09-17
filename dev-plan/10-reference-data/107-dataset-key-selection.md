# 107 — Choose the key column

**Phase** 10 · Reference data  |  **Depends on** [036](../03-design-system/036-app-choice-field.md), [106](106-dataset-import-csv.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The screen that ends every import: pick the column identifying a row, see the duplicate count for that choice before
the dataset is saved, and decide what to do about it.

## Files

- `frontend/lib/features/reference/presentation/dataset_key_screen.dart` (new)

## Steps

1. Offer every parsed column, with its duplicate count and a sample of values, so the obvious key is obvious.
2. Show the duplicate key count before the import completes, naming the first few colliding values.
3. A non-unique key is a decision, not a silent state: the user either picks another column, or confirms that
   duplicates are expected and the dataset is saved marked as such.

## Constraints

- The duplicate count is computed off the UI thread over the parsed rows, not by a query per column (FE-PERF-02).
- The warning offers a way forward rather than blocking the import (FE-SIMP-08).

## Definition of done

- [ ] A dataset with a non-unique key cannot be saved silently.
- [ ] Tests: widget test of `dataset_key_screen.dart` covering empty and failure states and the non-unique-key path.
