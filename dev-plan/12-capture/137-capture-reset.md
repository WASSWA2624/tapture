# 137 — Reset for the next item

**Phase** 12 · Capture  |  **Depends on** [113](../11-context/113-context-model.md), [136](136-save-immediate.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

After a save the session clears its evidence, captions and typed values, while context, pinned template and camera
settings stay exactly as they were, so the next item needs no re-selection.

## Files

- `frontend/lib/features/capture/domain/capture_reset.dart` (new)

## Steps

1. Clear session-scoped state only; leave the context snapshot, pinned template and last camera settings in place.
2. Start the next session with a fresh id, sharing no mutable state with the saved one.

## Constraints

- The reset never touches the saved record, its files or its rows (FE-SEC-08).

## Definition of done

- [ ] Capturing the next item requires re-selecting nothing.
- [ ] Tests: unit test that context, pinned template and camera settings survive a save and reset, that the new session shares no state with the old one, and that the saved record is untouched.
