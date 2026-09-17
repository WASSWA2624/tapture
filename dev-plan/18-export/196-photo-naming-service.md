# 196 — Photo naming and renaming on identification

**Phase** 18 · Export  |  **Depends on** [066](../05-file-storage/066-project-folder-service.md), [067](../05-file-storage/067-file-writer.md), [078](../07-account-and-settings/078-settings-store.md), [126](../12-capture/126-photo-tray.md), [172](../15-data-quality/172-identity-hash.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Photo file names are built from the project's configured pattern and the tokens available at capture time, and are
rewritten once a serial or asset number is confirmed, so a photo taken before identification still ships under a
meaningful name.

## Files

- `frontend/lib/core/export/photo_naming.dart` (new)
- `frontend/lib/core/export/photo_rename.dart` (new)

## Contract

```dart
class PhotoNaming {
  const PhotoNaming(this.pattern);
  /// Sanitised, collision-free name for [photo]; unresolved tokens fall back in a fixed order.
  String nameFor(PhotoNamingTokens tokens, {required Set<String> taken});
}

class PhotoRenamer {
  /// Renames every provisional file of [recordId] and updates its stored path in one transaction.
  Future<int> renameForIdentity(String recordId);
}
```

## Steps

1. Support the specification's token set, including each context level, record number, photo type and sequence;
   sanitise through 117 and de-duplicate against names already taken.
2. Rename the file and update the stored path in one transaction, so no row ever points at a missing file.
3. Keep the original filename in photo metadata and write a history entry for the rename.

## Constraints

- Raw evidence is append-only: renaming moves the file and records the old name, never rewrites pixels (FE-SEC-08).
- Names are derived only from the configured pattern; no writer invents its own naming (FE-CONS-09).

## Definition of done

- [ ] Names match the specification examples exactly, and two photos in one record never collide.
- [ ] A photo taken before identification ends up correctly named, with its original name still recoverable.
- [ ] References from records, the manifest and the photo index still resolve after a rename.
- [ ] Tests: unit tests of `photo_naming.dart` over the full token set and collision handling, and of `photo_rename.dart` asserting path rows and references stay consistent after renaming, with no Flutter binding.
