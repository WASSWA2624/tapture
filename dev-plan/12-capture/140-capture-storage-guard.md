# 140 — Storage guard in capture

**Phase** 12 · Capture  |  **Depends on** [069](../05-file-storage/069-storage-guard.md), [121](121-capture-screen.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Capture warns at the storage guard's warning threshold and refuses new evidence at its stop threshold, with a message
that names the free space left and offers export as the way out.

## Files

- `frontend/lib/features/capture/presentation/capture_storage_guard.dart` (new)

## Steps

1. Read both thresholds from the storage guard (124); never hardcode a size here.
2. Warn once per session, dismissibly, and keep capture fully working.
3. At the stop threshold refuse new writes only; a write already in flight completes rather than truncating.

## Constraints

- The warning never blocks; only the stop threshold does (FE-SIMP-08).
- The stop message names the next action and offers it (FE-SIMP-11).

## Definition of done

- [ ] A full device shows an actionable message with an export shortcut and loses no photo already taken.
- [ ] Tests: widget test of `capture_storage_guard.dart` at healthy, warning and full levels against a fake storage guard, asserting the warning is dismissible, capture continues after it, and the stop state offers export while completing an in-flight write.
