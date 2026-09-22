# 051 — Move the storage root to public Documents

**Phase** 23 · Hardening  |  **Depends on** [005](../05-file-storage/005-file-storage.md), [048](048-fix-storage-root-on-android.md), [049](049-save-downloads-to-public-tapture-folder.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On Android 11 and later, the `Tapture/` evidence folder lives in shared
storage at `Documents/Tapture/`. A person can open it in the Files app, and
it survives an uninstall. Android 10 and below, and a failed write probe,
keep the app-specific folder. Other platforms keep their current location.
Nothing already under `Android/data` is moved or deleted.

## Files

- `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`
- `frontend/lib/core/files/storage_root.dart`
- `frontend/test/core/files/storage_root_test.dart`

## Constraints

- Native access stays in `core/files/` behind `StorageRoot` (FE-STR-11).
- Raw evidence is never moved or deleted (FE-SEC-08).
- A location that fails the probe is a `StorageFailure` only when the
  fallback fails too (FE-CODE-06).
- No new permission (FE-SEC-07, task 235).
- Paths stay ASCII (FE-L10N-11).
- Seams only; no real shared storage in tests (FE-TEST-03).
- Do not change the database location, downloads, iOS, desktop, web,
  `AndroidManifest.xml`, or the feedback `BlobStore`.

## Definition of done

- [x] Android 11+ prefers public `Documents/Tapture` through the files
      channel.
- [x] `unsupported` and an unwritable public folder fall back to the app
      folder.
- [x] Both locations unwritable is a `StorageFailure`.
- [x] Resolving a writable public folder twice returns the same directory.
- [x] Tests: public used when writable; unsupported fallback; unwritable
      public fallback; both fail; existing missing/read-only tests.
