# 118 — Context presets: save and apply

**Phase** 11 · Context  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [113](113-context-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Save the current levels and pins under a name, and restore any saved set in one tap from a sheet, so moving between
two rooms costs one tap each way.

## Files

- `frontend/lib/features/context/presentation/context_preset_save.dart` (new)
- `frontend/lib/features/context/presentation/context_preset_list.dart` (new)

## Steps

1. Saving captures every level value and pin currently set, under a name unique within the project; a repeat name asks
   before overwriting.
2. The list shows presets most recently used first, with their values as the subtitle.
3. Applying sets the preset's values in one write; levels the preset does not name are cleared, and no cascade
   confirmation is shown because the operator chose the whole set.

## Constraints

- Save and list reuse the design system's sheet, list row and empty state, which names applying a preset as the next action (FE-CONS-01, FE-SIMP-11).

## Definition of done

- [ ] Moving between two rooms costs one tap each way.
- [ ] Saving under an existing name asks before overwriting and never silently replaces a preset.
- [ ] Tests: widget tests of `context_preset_save.dart` and `context_preset_list.dart` covering an empty list, a duplicate name, applying a preset that omits a level, and a repository failure.
