# 139 — Rapid capture mode

**Phase** 12 · Capture  |  **Depends on** [126](126-photo-tray.md), [136](136-save-immediate.md), [137](137-capture-reset.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The high-speed loop from the specification: item after item without leaving the camera, with a running list of captured
items and their photo counts.

## Files

- `frontend/lib/features/capture/presentation/rapid_mode_screen.dart` (new)

## Steps

1. One tap saves the current item raw, resets and returns to a live preview.
2. Show the running item list with photo counts, and allow reopening the last item to correct it.
3. Analyse nothing until the operator asks.

## Constraints

- Item-to-item and shutter-to-ready times are measured, not assumed (FE-PERF-01, FE-TEST-09).
- The item list is virtualised; a long run does not grow the frame budget (FE-PERF-03).

## Definition of done

- [ ] Four items with photos can be captured in under a minute.
- [ ] Tests: integration test of a four-item run asserting four records, the correct photo count on each, zero processing jobs, and that reopening the last item edits that item only.
