# 127 — Photo viewer, rotate and crop

**Phase** 12 · Capture  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [067](../05-file-storage/067-file-writer.md), [126](126-photo-tray.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Full-screen inspection with pinch and double-tap zoom, swiping between the record's photos and metadata on demand,
plus rotation stored as metadata and cropping written as a derived file — both reversible, both leaving the original
bytes alone.

## Files

- `frontend/lib/features/capture/presentation/photo_viewer_screen.dart` (new)
- `frontend/lib/features/capture/domain/photo_rotate.dart` (new)
- `frontend/lib/features/capture/presentation/photo_crop_screen.dart` (new)

## Steps

1. Pinch and double-tap to zoom; swipe between the record's photos; show caption, type and metadata on demand.
2. Store rotation as metadata and apply it to derived copies only; the original file is never rewritten.
3. Write the crop as a derived file linked to the original, computed in the isolate runner (033); reverting restores
   the full frame at its original orientation.

## Constraints

- Original bytes and hash are immutable; every edit writes beside the original (FE-SEC-08).
- Decode and crop off the UI thread; the full image is decoded only in the viewer (FE-PERF-02, FE-PERF-04).
- A missing or unreadable file renders the failure state rather than an empty box (FE-STATE-11).

## Definition of done

- [ ] The original file's hash is unchanged after rotating and cropping.
- [ ] Reverting always restores the full frame at its original orientation.
- [ ] Tests: widget tests of `photo_viewer_screen.dart` (single photo, swipe across several, missing file) and `photo_crop_screen.dart` (crop then revert); unit tests of `photo_rotate.dart` asserting metadata-only rotation with no Flutter binding.

## Out of scope

- Annotation, redaction and face blurring, which belong to phase 22 · Privacy and security.
