# 124 — Camera controls and document mode

**Phase** 12 · Capture  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [122](122-camera-permission-flow.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The four controls a field worker actually uses — flash, tap to focus, pinch to zoom, grid — and the paper-tuned mode
that detects the page boundary, offers a perspective-corrected higher-contrast copy, and keeps the original file
untouched.

## Files

- `frontend/lib/features/capture/presentation/camera_controls.dart` (new)
- `frontend/lib/features/capture/presentation/document_mode.dart` (new)

## Steps

1. Flash cycles off, auto, on and the choice is remembered for the next session.
2. Tap to focus with a visible indicator; pinch to zoom within the device's reported range; grid toggle persists.
3. Detect the page boundary in the isolate runner (033) and offer the corrected crop as a derived file linked to the
   original.
4. When no boundary is found, capture normally and say so rather than blocking the shutter.

## Constraints

- Controls are 48dp or larger, glove-friendly, and legible in the outdoor theme (FE-A11Y-01, FE-A11Y-09, FE-THEME-03).
- The last used setting is the default; the app does not ask what it already knows (FE-SIMP-05).
- The original bytes are never rewritten; correction writes beside them (FE-SEC-08).

## Definition of done

- [ ] Controls are usable with gloves and remain readable in the outdoor theme.
- [ ] The original photo is retained unchanged alongside the corrected copy.
- [ ] Flash, zoom and grid choices survive leaving and re-entering capture.
- [ ] Tests: widget test of `camera_controls.dart` asserting flash cycling, focus, zoom clamping, grid persistence and the accessibility matchers against a fake camera service; widget test of `document_mode.dart` covering boundary detected, not detected and correction failed.
