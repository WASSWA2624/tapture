# 119 — Optional auto-clear and movement prompt

**Phase** 11 · Context  |  **Depends on** [026](../02-foundation/026-permissions-service.md), [078](../07-account-and-settings/078-settings-store.md), [113](113-context-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two settings, both off by default: clear the lowest level after a configurable idle interval, and ask the operator to
confirm the context after moving a configured distance.

## Files

- `frontend/lib/features/context/domain/context_auto_clear.dart` (new)
- `frontend/lib/features/context/domain/context_movement_prompt.dart` (new)

## Steps

1. Read the idle interval and the movement distance from the settings store (136); both features are inert until
   switched on.
2. Auto-clear fires at most once per idle period, clears only the lowest level, and shows one undo toast that restores
   the cleared value.
3. The movement prompt activates only where GPS is already enabled and location permission already granted; it asks
   for confirmation and never changes the context itself.

## Constraints

- No location is read, and no location permission requested, while the prompt is off (FE-SEC-07).
- Both settings default to off and are justified by the specification, not by taste (FE-SIMP-12).
- Time and distance come from injected services so tests need no real clock or fix (FE-STR-11).

## Definition of done

- [ ] With both settings off, the context never changes on its own and no location call is made anywhere.
- [ ] Undo after an auto-clear restores the cleared value exactly.
- [ ] Tests: unit tests of `context_auto_clear.dart` and `context_movement_prompt.dart` with a fake clock and a fake location source, covering off, fired, undone and permission-denied, with no Flutter binding.
