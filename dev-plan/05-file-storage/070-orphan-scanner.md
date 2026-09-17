# 070 — Orphan file scanner

**Phase** 05 · File storage  |  **Depends on** [063](../04-data-layer/063-db-integrity-check.md), [066](066-project-folder-service.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A scan of one project's folder tree against its rows that reports both directions — files with no row, rows with no file
— with sizes, and offers adoption or an evidence-missing flag as an explicit user choice.

## Files

- `frontend/lib/core/files/orphan_scanner.dart` (new)

## Contract

```dart
class OrphanReport {
  final List<OrphanFile> filesWithoutRows;    // path, bytes, detected kind
  final List<MissingFile> rowsWithoutFiles;   // entity type, id, expected path
  final int reclaimableBytes;
}

abstract interface class OrphanScanner {
  Future<Result<OrphanReport>> scan(String projectId, {void Function(double)? onProgress});
  Future<Result<void>> adopt(OrphanFile file, {required String recordId});
  Future<Result<void>> flagMissing(MissingFile row);
}
```

## Steps

1. Walk the project tree in batches, skipping `.cache` and `.part` files, and compare against `photos` and attachment
   rows by relative path.
2. Report both directions with byte sizes and progress; hash a candidate only when a path match is ambiguous.
3. Adopt an orphan file by inserting a row through the normal media path so it gains a hash and merge columns; flag a
   missing file on its row instead of deleting it.

## Constraints

- The scan deletes nothing and moves nothing on its own; every action is a separate, confirmed user choice (rule 1 of
  the standard).
- Walking and hashing run off the UI thread with progress and cancellation (FE-PERF-02, FE-PERF-10).

## Definition of done

- [ ] A project with one stray file and one deleted file reports exactly one entry on each side, with sizes.
- [ ] A cancelled scan leaves no partial report and nothing changed on disk.
- [ ] Adoption produces a normal media row with hash and merge columns; flagging leaves the row and its evidence intact.
- [ ] Tests: `frontend/test/core/files/orphan_scanner_test.dart` seeds a stray file, a row whose file was removed and a
      `.cache` entry that must be ignored, then asserts the report, the adoption path and that nothing is deleted.

## Out of scope

- Row-only integrity problems; those are reported by task 063.
