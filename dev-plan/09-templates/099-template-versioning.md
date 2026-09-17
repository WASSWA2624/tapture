# 099 — Template versioning and record migration

**Phase** 09 · Templates  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [049](../04-data-layer/049-drift-setup.md), [088](088-template-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A version bump on any structural template change, a recorded diff between consecutive versions, and the screen that
shows exactly what a migration will do before any record moves forward.

## Files

- `frontend/lib/features/templates/domain/template_versioning.dart` (new)
- `frontend/lib/features/templates/presentation/template_migration_screen.dart` (new)

## Steps

1. Bump on any structural change — field added, removed, retyped, renamed, reordered, hidden, or requiredness
   changed — and record what changed between the two versions.
2. A captured record keeps the version it was captured under, and keeps rendering and exporting under it.
3. The migration screen lists fields added, removed and retyped with the count of records each affects, and requires
   explicit confirmation before moving them.

## Constraints

- Versioning lives in `domain/` as pure Dart, with no Flutter or Drift import (FE-STR-05).
- Migration is a single durable transaction: a failure part-way leaves every record on its old version (FE-STATE-07).

## Definition of done

- [ ] Old records still render and export correctly after a template edit, and keep their captured version.
- [ ] No record is migrated without the user first seeing the added, removed and retyped fields and the counts.
- [ ] Tests: unit test that a record keeps its captured version across a bump and that the recorded diff matches the change; widget test of `template_migration_screen.dart` covering empty and failure states.
