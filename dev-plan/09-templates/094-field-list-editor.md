# 094 — Field list editor, reorder and delete

**Phase** 09 · Templates  |  **Depends on** [038](../03-design-system/038-app-card.md), [041](../03-design-system/041-app-dialog-service.md), [088](088-template-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The one screen where a template's fields are managed: an ordered list showing each field's label, type and
requiredness badge, with add, edit, drag reorder, and a delete that retires values instead of destroying them.

## Files

- `frontend/lib/features/templates/presentation/field_list_screen.dart` (new)
- `frontend/lib/features/templates/presentation/field_reorder.dart` (new)
- `frontend/lib/features/templates/presentation/field_delete_action.dart` (new)

## Steps

1. Render each field as an `AppListTile` with label, type and requiredness badge; keep the list keyboard-navigable.
2. Drag order is capture order and export order. Reordering changes neither stored values nor output column mapping.
3. Delete warns with the count of records holding a value for the field, then marks those values retired rather than
   deleting them.

## Constraints

- Reorder is reachable without a drag gesture — a move-up/move-down affordance on each row with a semantic label
  (FE-A11Y-01, FE-A11Y-02).
- The delete dialog comes from the shared dialog service and names the consequence and the count (FE-SIMP-07).
- Requiredness renders through `AppStatusPill`, never a bespoke badge (FE-CONS-06).

## Definition of done

- [x] This list is the only place fields are managed.
- [x] Reordering never changes stored values or output column mapping.
- [x] Deleting a field never loses captured data: retired values survive and export as retired.
- [x] Tests: widget test of `field_list_screen.dart` covering empty and failure states and a reorder; test that retired values survive a delete and export as retired.
