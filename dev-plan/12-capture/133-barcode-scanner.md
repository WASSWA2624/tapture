# 133 — Barcode scanner and continuous scan mode

**Phase** 12 · Capture  |  **Depends on** [005](../01-orchestration/005-dependency-allowlist.md), [122](122-camera-permission-flow.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One-handed scanning of the symbologies listed in the specification — a scan region, torch toggle and the decoded value
with a confirm action — plus a continuous mode for stock counting that debounces repeat reads and keeps a running
count.

## Files

- `frontend/lib/features/capture/presentation/barcode_scanner_screen.dart` (new)
- `frontend/lib/features/capture/presentation/barcode_continuous_mode.dart` (new)

## Steps

1. Decode from the camera stream inside a visible scan region; show the decoded value with confirm and rescan.
2. Continuous mode stays open between reads, debounces the same code, shows a running count and allows undo of the last
   scan.

## Constraints

- The decoded string is data: quoted, never interpolated into a query or a path (FE-SEC-05).
- The scanner plugin is on the dependency allowlist checked by task 005.
- Torch and confirm are 48dp targets with semantic labels, usable one-handed (FE-A11Y-01, FE-A11Y-02, FE-A11Y-09).

## Definition of done

- [ ] A worn label still scans within a couple of seconds.
- [ ] Fifty items can be counted without leaving the screen, with the last scan undoable.
- [ ] Tests: widget tests of `barcode_scanner_screen.dart` (no code, decoded, unreadable code, camera failure) and `barcode_continuous_mode.dart` (debounce of a repeated code, running count, undo of the last scan) against a fake scanner.
