# 138 — Crash recovery for an unsaved session

**Phase** 12 · Capture  |  **Depends on** [120](120-capture-session-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On launch an interrupted session is detected and the operator is offered resume or discard, with its photo count named
on the prompt.

## Files

- `frontend/lib/features/capture/presentation/capture_recovery_prompt.dart` (new)

## Steps

1. Detect an unfinished session at launch, before the capture screen is reachable.
2. Offer resume or discard, naming the photo count; resume restores photos, captions and typed values.
3. Discard asks for confirmation and tombstones, so the evidence remains recoverable.

## Constraints

- Discarding removes no file before the retention purge (FE-SEC-08).
- No path through this prompt may lose a photo, a caption or a typed value (FE-SIMP-09).

## Definition of done

- [ ] A crash during capture never silently discards photos.
- [ ] Tests: widget test of an interrupted session asserting the photo count on the prompt, that resume restores photos, captions and values, and that discard leaves the files recoverable.
