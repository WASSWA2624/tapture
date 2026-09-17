# 116 — Cascade clearing

**Phase** 11 · Context  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [115](115-context-bar.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Pure rules that decide which lower levels a change to a higher level clears, and the single confirmation that names
them before anything is cleared.

## Files

- `frontend/lib/features/context/domain/context_cascade.dart` (new)

## Steps

1. Compute the affected levels from the hierarchy order: everything below the changed level, ignoring pins.
2. Confirm once through `AppDialogService`, in the specification's wording, naming each level that will clear and its
   current value.
3. Apply the change and the clears as one write; declining leaves every level, including the changed one, untouched.

## Constraints

- Domain stays pure Dart: the rules return the affected levels, the caller shows the dialog (FE-STR-05).
- One confirmation, never a chain, with a safe default and a way out (FE-SIMP-07).

## Definition of done

- [ ] Changing district never leaves a stale facility or department attached to new records.
- [ ] Declining the confirmation changes nothing at all, including the level that was being set.
- [ ] Tests: unit tests of `context_cascade.dart` over zero-, one- and three-level hierarchies and over a change to the lowest level, with no Flutter binding.
