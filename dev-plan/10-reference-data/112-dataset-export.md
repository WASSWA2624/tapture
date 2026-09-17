# 112 — Export a dataset

**Phase** 10 · Reference data  |  **Depends on** [105](105-dataset-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A dataset written back out as CSV or JSON, columns in their import order, including the rows added on the device, so
an office system can take back what the field corrected.

## Files

- `frontend/lib/features/reference/data/dataset_export.dart` (new)

## Steps

1. Write columns in `ReferenceDataset.columns` order, with the key column first.
2. Include rows flagged `addedOnDevice`, marked so the receiving system can tell them from the rows it sent.
3. Stream to the target file rather than building the whole document in memory.

## Constraints

- Export streams and runs off the UI thread; a ten-thousand-row dataset does not stall the interface
  (FE-PERF-02, FE-PERF-07).

## Definition of done

- [ ] An exported dataset re-imports as the same dataset, rows added on the device included.
- [ ] Tests: repository tests for `dataset_export.dart` against an in-memory database, plus the fake later tests use; a round-trip test that export then import through `dataset_csv_import.dart` and `dataset_json_import.dart` yields the same rows and column order.
