# 221 — Create records from rows, with duplicate handling

**Phase** 20 · Data import  |  **Depends on** [050](../04-data-layer/050-column-mixins.md), [162](../14-records/162-record-model.md), [172](../15-data-quality/172-identity-hash.md), [220](220-import-records-mapping.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Mapped rows become records with source `IMPORTED_TABLE`, inserted in one transaction with progress, each row validated
and each row that matches an existing record settled by the operator before it is written.

## Files

- `frontend/lib/features/import/domain/record_import.dart` (new)
- `frontend/lib/features/import/domain/import_duplicates.dart` (new)

## Contract

```dart
enum DuplicateChoice { keepExisting, replace, merge }

class RecordImportResult {
  const RecordImportResult(this.created, this.updated, this.skipped, this.failures);
  final List<RowFailure> failures; // row index and reason
}

class RecordImport {
  Stream<ImportProgress> run(RecordMapping mapping, {required CancellationToken token});
}
```

## Steps

1. Validate per row and collect failures with their row number and reason rather than aborting the import.
2. Compare each incoming row against existing records through the detector of 320 before inserting it.
3. Offer keep existing, replace and merge per match, with an apply-to-all option for the rest of the run.
4. Insert in batches inside one transaction, reporting progress per batch.

## Constraints

- Reuse the detector of 320; import defines no similarity logic of its own (FE-CONS-02).
- Batch inserts run off the UI thread; ten thousand rows must not stall a frame (FE-PERF-02, FE-PERF-08).

## Definition of done

- [ ] Ten thousand rows import without freezing the interface, with visible progress.
- [ ] Invalid rows are collected with their reasons and the valid rows still import.
- [ ] No import silently overwrites an existing record; every match is settled by a choice, which can be applied to all.
- [ ] Tests: unit tests of `record_import.dart` over a fixture containing invalid rows and of `import_duplicates.dart` over each `DuplicateChoice` plus apply-to-all, with no Flutter binding.
