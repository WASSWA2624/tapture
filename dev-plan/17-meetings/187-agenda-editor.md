# 187 — Agenda and attendee editors

**Phase** 17 · Meetings  |  **Depends on** [038](../03-design-system/038-app-card.md), [186](186-meeting-template.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The two list editors a meeting starts with: agenda items, which become its discussion sections, and attendees entered
by hand, with apologies kept distinct from attendance.

## Files

- `frontend/lib/features/meetings/presentation/agenda_editor.dart` (new)
- `frontend/lib/features/meetings/presentation/attendee_editor.dart` (new)

## Steps

1. Agenda items add, reorder by drag and remove; each item becomes a discussion section and keeps its order through to
   export.
2. Attendees carry name, title, organisation and contact, plus a status distinguishing present from apologies.
3. Both editors build on the shared list tile of 065 and the shared confirm for removal; neither invents its own row
   (FE-CONS-06).

## Definition of done

- [ ] Each agenda item becomes a discussion section, in the order the user set.
- [ ] An apology is recorded as an apology and never counted as attendance, in the record and on export.
- [ ] Tests: widget test of `agenda_editor.dart` covering add, reorder and remove, and of `attendee_editor.dart`
      covering a present attendee and an apology — both including their empty and failure states.
