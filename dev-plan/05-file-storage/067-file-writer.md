# 067 — Atomic file writer and context relocation

**Phase** 05 · File storage  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [065](065-storage-root.md), [066](066-project-folder-service.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The only two ways bytes move inside the storage tree: a writer that streams to a temporary name, hashes in the same
pass and renames into place, and a relocator that moves a record's files when its context is set or corrected, in the
same transaction as the path update.

## Files

- `frontend/lib/core/files/file_writer.dart` (new)
- `frontend/lib/core/files/file_relocation.dart` (new)

## Contract

```dart
class WrittenFile {
  final String relativePath;
  final String sha256;
  final int byteLength;
}

abstract interface class FileWriter {
  Future<Result<WrittenFile>> write(Stream<List<int>> bytes, String relativePath);
  Future<Result<WrittenFile>> copyIn(File source, String relativePath);
}

abstract interface class FileRelocation {
  Future<Result<int>> relocateRecord(String recordId);   // returns files moved
}
```

## Steps

1. Write to `<target>.part` in the destination directory, hash while streaming, `flush`, then rename — so the target
   either does not exist or is complete and hashed.
2. Sweep stale `.part` files on the next write to the same directory; never resume one.
3. Map a full disk, a permission loss and a vanished parent directory to `StorageFailure` variants with recovery
   actions, leaving no partial file behind.
4. Relocate by computing the new relative path, moving each file, then updating `photos.relativePath` and the
   attachment rows inside one transaction; roll back the moves if the transaction fails and the rows if a move fails.
5. Handle the unfiled case: photos captured under `_unfiled` move into the context tree when a context is applied after
   capture.

## Constraints

- Streaming and hashing read in chunks, off the UI thread; nothing loads a whole photo or document into memory
  (FE-PERF-02, FE-PERF-07).
- Relocation moves files and never copies-then-deletes across the same volume; originals are never rewritten
  (FE-SEC-08).
- Persist before confirming: a caller sees success only after the rename and the row update are both durable
  (FE-STATE-07).

## Definition of done

- [x] A simulated failure mid-write leaves the target absent and no `.part` file visible to the app.
- [x] The hash returned by the writer equals the hash of the file re-read from disk.
- [x] Correcting a facility name relocates every file of the affected records with no stored path left dangling, and a
      failure part-way leaves paths and files still agreeing.
- [x] Tests: `frontend/test/core/files/file_writer_test.dart` covers the interrupted write, the full-disk failure and
      hash equality; `file_relocation_test.dart` asserts files and rows agree after success, after a failed move and
      after a failed transaction, including the `_unfiled` promotion.
