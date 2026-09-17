# 065 — Storage root resolution

**Phase** 05 · File storage  |  **Depends on** [021](../02-foundation/021-result-and-failures.md), [026](../02-foundation/026-permissions-service.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One provider that resolves, creates and hands out the visible `Tapture/` root under the device's documents directory,
and reports an unwritable or absent location as a recoverable failure rather than throwing.

## Files

- `frontend/lib/core/files/storage_root.dart` (new)

## Contract

```dart
abstract interface class StorageRoot {
  Future<Result<Directory>> resolve();
  Future<Result<Directory>> cacheDir();   // Tapture/.cache
}

final storageRootProvider = Provider<StorageRoot>(...);
```

## Steps

1. Resolve the platform documents directory through the permissions service, create `Tapture/` and `Tapture/.cache` if
   absent, and memoise the result for the process.
2. Probe writability by creating and removing a marker file; report the outcome as a `StorageFailure` naming the path
   and the recovery action.
3. Expose the root only through the provider, so no caller composes an absolute path of its own.

## Constraints

- Every filesystem path in the app is derived from this provider; a hardcoded root or a plugin call outside `core/files/`
  is a defect (FE-STR-11, FE-CODE-09).
- `.cache` is the only place derived artefacts may live, and it stays disposable (rule 1 of the standard).

## Definition of done

- [ ] The folder is visible in a file manager and over a cable, with no media-scanner exclusion applied.
- [ ] A read-only or missing location yields a failure carrying a recovery action, and the app stays usable.
- [ ] Resolving twice creates the tree once and returns the same directory.
- [ ] Tests: `frontend/test/core/files/storage_root_test.dart` resolves into a temporary directory, asserts idempotent
      creation, and asserts the failure variant when the location is not writable.
