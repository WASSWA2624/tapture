# 206 — Export screen, progress and cancellation

**Phase** 18 · Export  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [033](../03-design-system/033-app-page.md), [042](../03-design-system/042-app-progress-steps.md), [194](194-export-scope.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The one screen that assembles a whole export: format, scope, options and extras with a live record count, then
per-stage progress while it runs and a cancellation that leaves nothing behind.

## Files

- `frontend/lib/features/exports/presentation/export_screen.dart` (new)
- `frontend/lib/features/exports/presentation/export_progress.dart` (new)

## Steps

1. Open with the project's remembered options already applied, so a default export is one tap.
2. Show progress per stage — records, photos, reports, archive — using the shared progress steps control.
3. On cancellation, stop the isolate and delete every partial file, including the half-written archive.

## Constraints

- Export is the single primary action of this screen (FE-SIMP-01); scope and options come from 360 unchanged.
- Progress arrives as isolate messages; the screen performs no export work itself (FE-PERF-02).

## Definition of done

- [ ] A default export needs one tap after opening the screen.
- [ ] Each stage reports progress, and the interface stays responsive throughout.
- [ ] A cancelled export leaves no partial output file or archive on disk.
- [ ] Tests: widget tests of `export_screen.dart` and `export_progress.dart` covering the four states, the one-tap default and a cancellation asserting no file remains.
