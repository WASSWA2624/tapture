# 064 — Optional database encryption

**Phase** 04 · Local database  |  **Depends on** [027](../02-foundation/027-secure-storage-service.md), [049](049-drift-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A setting that swaps the connection for an encrypted one with the key held in secure storage, migrating the existing
plain database in place with progress, without a single query or DAO changing.

## Files

- `frontend/lib/core/db/encryption.dart` (new)
- `frontend/lib/core/db/app_database.dart` (edit)

## Contract

```dart
abstract interface class DatabaseEncryption {
  Future<Result<bool>> isEnabled();
  Future<Result<void>> enable({required void Function(double) onProgress});
  Future<Result<void>> disable({required String confirmation});
}
```

## Steps

1. Generate the key on enable, store it only through the secure storage service, and open the encrypted connection
   through the same `AppDatabase` factory path.
2. Copy the plain database into the encrypted one, verify row counts per table, then delete the plain file — keeping a
   safety copy until verification passes.
3. Report progress so a large database never looks frozen, and make the whole operation resumable after a kill.
4. Require typed confirmation to disable, and treat a missing or unreadable key as a recoverable failure with a clear
   recovery action, never a wipe.

## Constraints

- The key exists only in platform secure storage: never in the database, preferences, logs, exports or bundles
  (FE-SEC-01, FE-SEC-02).
- Encryption must be demonstrable, not claimed: a test proves the file cannot be read without the key (FE-SEC-11).
- The copy runs off the UI thread in chunks (FE-PERF-02, FE-PERF-07).

## Definition of done

- [ ] Enabling encryption preserves every row and every table's row count matches before the plain file is removed.
- [ ] A kill part-way through leaves either the plain database or the verified encrypted one, never a half-copied file.
- [ ] Disabling requires explicit typed confirmation; a lost key produces a stated failure rather than data loss.
- [ ] Tests: `frontend/test/core/db/encryption_test.dart` asserts the encrypted file fails to open without the key,
      opens with it, that row counts survive enable and disable, and that an interrupted enable is resumable.
