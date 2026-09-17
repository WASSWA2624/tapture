# 128 — Delete, retake and move photos

**Phase** 12 · Capture  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [067](../05-file-storage/067-file-writer.md), [123](123-camera-shutter.md), [126](126-photo-tray.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three corrective actions on evidence: remove a photo behind a destructive confirmation with working undo, replace
one in place without losing its position, type or caption, and move selected photos to another record with files and
rows changed in one transaction.

## Files

- `frontend/lib/features/capture/presentation/photo_delete_action.dart` (new)
- `frontend/lib/features/capture/presentation/photo_retake_action.dart` (new)
- `frontend/lib/features/capture/presentation/photo_move_action.dart` (new)

## Steps

1. Delete confirms through `AppDialogService` naming the consequence, tombstones the row, removes it from the tray and
   offers undo through `AppSnackbar`; the file stays until the retention purge so undo always works.
2. Retake keeps the old file as a superseded version and puts the new photo at the same position with the same type and
   caption.
3. Move relocates files (120) and rows in one transaction and flags affected field values as evidence changed.

## Constraints

- Deletion is a tombstone; files are removed only by the purge job after the retention window (FE-SEC-08).
- A failure on any of the three paths leaves the photo, its file and its metadata intact and offers recovery (FE-SIMP-09).
- Each action records who, when, from what and to what (FE-SEC-09).

## Definition of done

- [ ] Undo restores a deleted photo at its original position with its caption and type.
- [ ] Retaking never changes a photo's position in the tray.
- [ ] Moving photos never leaves a dangling evidence link or an orphaned file.
- [ ] Tests: widget tests of delete-then-undo, retake preserving position and metadata, and a multi-select move across records; transaction test asserting a mid-move failure rolls back files and rows together.

## Out of scope

- Deleting a whole record, and the retention purge that finally removes files; both belong to phase 14 · Records.
