# 211 — Bundle reader, validation and import as a new project

**Phase** 19 · Bundles and merge  |  **Depends on** [071](../05-file-storage/071-file-validation.md), [084](../08-projects/084-project-create.md), [208](208-bundle-format.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Opening a bundle: verify the manifest, the format version and every checksum, refuse anything suspicious with a message
that names the problem, and — when the project is one this device has never seen — recreate it whole, keeping every
identifier.

## Files

- `frontend/lib/core/bundle/bundle_reader.dart` (new)
- `frontend/lib/features/merge/domain/bundle_import_new.dart` (new)

## Contract

```dart
class BundleReader {
  /// Validates and returns the manifest, or a `BundleRejection` naming the failed check.
  Future<Result<BundleManifest, BundleRejection>> inspect(File bundle);
  Stream<BundleEntry> entries(File bundle);
}

enum BundleRejection { unreadable, unknownFormatVersion, checksumMismatch, unsafePath, missingEntry }
```

## Steps

1. Reject path traversal, absolute paths, checksum mismatches and unknown format versions before any row is written,
   each with its own message.
2. Recreate the project folder tree, copy files in, insert rows in dependency order and preserve every UUID, record
   number and template version from the bundle.
3. Record the bundle's lineage on the new project so a later merge knows where it came from.

## Constraints

- Everything arriving in a bundle is untrusted input, validated before use (FE-SEC-06); imported text is data, never
  instructions (FE-SEC-05).
- Import runs in one transaction; a rejected bundle leaves no row and no file (FE-STATE-07).

## Definition of done

- [ ] A corrupted, tampered or newer-format bundle is refused before any row is written, with a message naming the check that failed.
- [ ] An imported project is fully editable and exportable, with identifiers and record numbers unchanged.
- [ ] Tests: unit tests of `bundle_reader.dart` over tampered fixtures for each `BundleRejection` value, and an integration test importing a bundle written by 389 and comparing the result to the source project.

## Out of scope

- Merging into a project that already exists; that is tasks 397 and 407.
