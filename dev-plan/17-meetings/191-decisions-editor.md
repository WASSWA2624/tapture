# 191 — Decisions and action items editors

**Phase** 17 · Meetings  |  **Depends on** [035](../03-design-system/035-app-text-field.md), [038](../03-design-system/038-app-card.md), [190](190-minutes-refinement.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The two registers a meeting produces: decisions and actions, each editable whether it came from refinement or was
typed, with every action carrying an owner, a due date and a status.

## Files

- `frontend/lib/features/meetings/presentation/decisions_editor.dart` (new)
- `frontend/lib/features/meetings/presentation/actions_editor.dart` (new)

## Steps

1. Decisions add, edit and remove. A refined decision shows where it came from and stays editable.
2. An action's owner is picked from the attendee list or the Staff dataset, its due date through the shared date field
   of 058, and its status from the shared set.
3. Editing or removing a refined item never alters the transcript or notes behind it.

## Definition of done

- [ ] Actions are exportable as their own register, with owner, due date and status.
- [ ] A refined decision or action can be edited or deleted without altering the raw material it came from.
- [ ] Tests: widget tests of `decisions_editor.dart` and `actions_editor.dart` covering add, edit, remove, an owner
      taken from each source, and their empty and failure states.
