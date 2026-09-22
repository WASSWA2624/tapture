# 048 — Fix the storage root on Android

**Phase** 23 · Hardening  |  **Depends on** [005](../05-file-storage/005-file-storage.md), [007](../07-account-and-settings/007-account-and-settings.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On Android, `StorageRoot.resolve()` creates and returns the `Tapture/` folder
without asking for any permission. Storage settings then shows the real cache
and per-project totals, and Clear cache works.

## Files

- `frontend/lib/core/files/storage_root.dart`
- `frontend/test/core/files/storage_root_test.dart`
- `frontend/test/features/settings/presentation/storage_settings_screen_test.dart`

## Constraints

- Platform folders stay behind `StorageRoot` in `core/files/` (FE-STR-11).
- An unwritable or missing folder is still a `StorageFailure` with a recovery
  action (FE-CODE-06).
- Docs on `StorageRoot()` and `resolve()` no longer say it asks
  `PermissionsService` (FE-CODE-12).
- Tests use fakes and keep the unwritable-location failure (FE-TEST-03,
  FE-TEST-10).
- Clear cache still prunes `.cache` only (FE-SEC-08).
- Add no permission to the manifest (task 235).
- Do not move the root (prompt 004), change `AppPermission.storage`, drop
  the `_usageOnly` fallback, or change the database location.

## Definition of done

- [x] Resolving the root never asks for a permission and still creates
      `Tapture/` plus `Tapture/.cache`.
- [x] With a resolvable root, Storage shows the real cache size, not 0 B.
- [x] A read-only or missing location still returns a `StorageFailure` with a
      recovery action.
- [x] Tests: never-asks-permission create; existing idempotence and
      missing/read-only `StorageFailure` tests; Storage shows the seeded
      cache size.
