# 063 — Database integrity check

**Phase** 04 · Local database  |  **Depends on** [049](049-drift-setup.md), [050](050-column-mixins.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A startup check that finds broken references early and reports them as findings, never repairing or deleting anything by
itself.

## Files

- `frontend/lib/core/db/integrity_check.dart` (new)

## Contract

```dart
sealed class IntegrityFinding {
  String get entityType;
  String get entityId;
  String get detail;
}

Future<Result<List<IntegrityFinding>>> runIntegrityCheck(AppDatabase db);
```

## Steps

1. Detect record fields whose record is gone, photos and attachments whose file is missing, jobs and evidence rows
   pointing at deleted records, and rows deleted without a tombstone.
2. Run `PRAGMA foreign_key_check` and fold its output into the same findings list.
3. Run off the UI thread with a cap on rows examined per pass, and return findings for the maintenance screen to render.

## Constraints

- Findings are reported, never acted on: no delete, no rewrite, no silent repair (rule 1 of the standard).
- The pass streams rows in batches so a 10,000-record project does not load into memory (FE-PERF-02, FE-PERF-07).

## Definition of done

- [ ] A database with deliberately orphaned rows produces one finding per problem, each naming entity type and id.
- [ ] A clean database produces an empty list and adds no measurable delay to cold start (FE-PERF-01).
- [ ] Running the check twice changes nothing on disk.
- [ ] Tests: `frontend/test/core/db/integrity_check_test.dart` seeds orphaned fields, a missing photo file, a job on a
      deleted record and a tombstone-less delete, and asserts one finding each plus an unchanged row count afterwards.

## Out of scope

- The maintenance screen that renders findings, and file-side orphan detection; that is task 070.
