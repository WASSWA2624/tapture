# 117 — Apply context to records and the folder path

**Phase** 11 · Context  |  **Depends on** [054](../04-data-layer/054-records-table.md), [066](../05-file-storage/066-project-folder-service.md), [113](113-context-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A new record is prefilled from the current context with source `CONTEXT` and carries the whole context as a snapshot;
editing one of those values on a record changes that record alone; and the record's snapshot drives the folder tree
its photos land in.

## Files

- `frontend/lib/features/context/domain/context_application.dart` (new)
- `frontend/lib/features/context/domain/context_override.dart` (new)
- `frontend/lib/features/context/domain/context_folder_link.dart` (new)

## Steps

1. Write every level and pin into `record_fields` with source `CONTEXT`, then store the whole context as the record's
   snapshot so later context changes cannot rewrite history.
2. An edit marks the field overridden on that record and leaves the project context and every other record untouched.
3. Feed the record's own snapshot — not the live context — to the photo path builder (118).

## Constraints

- The prefilled value is raw evidence: an override writes a new value beside it with an audit entry, never over it (FE-SEC-08, FE-SEC-09).
- Path segments derived from context values stay ASCII and filesystem-safe (FE-L10N-11).

## Definition of done

- [ ] Ten records captured in one room all carry the same three values with no typing.
- [ ] Correcting one record's department moves neither the operator's context nor any other record.
- [ ] The on-disk tree mirrors the specification's example exactly for a three-level context.
- [ ] Tests: unit tests asserting value and source on a new record, and that the project context and sibling records are unchanged after an override; integration test capturing into a three-level context and asserting the resulting folder path.
