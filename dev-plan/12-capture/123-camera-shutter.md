# 123 — Shutter, immediate save and quality warning

**Phase** 12 · Capture  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [066](../05-file-storage/066-project-folder-service.md), [067](../05-file-storage/067-file-writer.md), [122](122-camera-permission-flow.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One shutter press writes the photo to its context folder, hashes it, inserts the row, attaches it to the session and
returns the camera to ready. The saved image is then scored for blur, darkness, overexposure and small text, and any
finding appears as an advisory hint offering retake or keep.

## Files

- `frontend/lib/features/capture/domain/take_photo.dart` (new)
- `frontend/lib/features/capture/domain/image_quality.dart` (new)

## Steps

1. Build the path (118), write the file (119), hash it, insert the row and add it to the session — all in the isolate
   runner (033), with the preview still live.
2. Confirm with haptics and a shutter flash; the next shot is accepted before the previous one finishes scoring.
3. Score the image only after it is durably written; keep is the default choice on the hint.

## Constraints

- Shutter to ready is under 400ms on a mid-range device, asserted by a measurement in the pull request (FE-PERF-01, FE-TEST-09).
- Quality findings are warnings: they always offer keep and never gate a save (FE-SIMP-08).
- Haptic confirmation on capture is required, not decorative (FE-A11Y-09).

## Definition of done

- [ ] Shutter to ready is under 400 milliseconds on a mid-range device.
- [ ] A quality warning never prevents saving and never discards the photo.
- [ ] Tests: integration test that ten rapid shots produce ten files and ten rows with distinct hashes and correct order; unit tests of `image_quality.dart` over dark, blurry, overexposed, small-text and clean fixtures; a measurement test for the shutter budget.

## Out of scope

- Reading anything out of the image. Scoring is advisory only; OCR and extraction belong to phase 13 · Processing.
