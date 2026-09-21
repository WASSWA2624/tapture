# 335 — Show storage volume totals and set the root

**Phase** 05 · File storage  |  **Depends on** [069](069-storage-guard.md), [065](065-storage-root.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Storage shows total, used and available bytes beside the headroom words, and
lets the operator choose the storage-root folder. Existing files stay where
they are.

## Files

- `frontend/lib/core/files/volume_stats.dart`
- `frontend/lib/core/files/storage_guard.dart`
- `frontend/lib/core/files/storage_root.dart`
- `frontend/lib/core/files/folder_picker.dart`
- `frontend/lib/core/files/folder_picker_io.dart`
- `frontend/lib/core/files/folder_picker_web.dart`
- `frontend/lib/core/files/folder_picker_stub.dart`
- `frontend/lib/features/settings/presentation/storage_settings_screen.dart`
- `frontend/lib/features/settings/domain/setting_keys.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`
- `frontend/test/core/files/volume_stats_test.dart`
- `frontend/test/core/files/storage_guard_test.dart`
- `frontend/test/core/files/storage_root_test.dart`
- `frontend/test/core/files/folder_picker_test.dart`
- `frontend/test/features/settings/presentation/storage_settings_screen_test.dart`

## Constraints

- Only `StorageGuard` and the existing files channel read the volume
  (FE-STR-11). No new package (FE-FLOW-06).
- A failed volume read is the error state, not ample (FE-STATE-11, FE-A11Y-05).
- The path is a preference, not a secret. Do not move or delete evidence
  (FE-SEC-01, FE-SEC-08).
- Tests never run `df` or PowerShell (FE-TEST-03).

## Definition of done

- [x] Storage shows total, used and available through `Copy.fileSize`, plus
      the ample, low or critical label.
- [x] A failed volume probe shows the error state with retry.
- [x] An empty root key still resolves through today's Documents fallback.
- [x] A saved writable folder is the path `resolve` returns after restart.
- [x] A failed write probe does not persist the path.
- [x] Web does not show the folder picker.
- [x] Tests cover the parser, the fake, the three figures and the path row.
