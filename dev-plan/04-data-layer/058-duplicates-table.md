# 058 — Duplicates and variances tables

**Phase** 04 · Local database  |  **Depends on** [054](054-records-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The two review queues a person works through: detected duplicate record pairs with how a human resolved them, and the
as-recorded versus as-found differences that verification mode produces.

## Files

- `frontend/lib/core/db/tables/duplicates.dart` (new)
- `frontend/lib/core/db/tables/variances.dart` (new)

## Steps

1. Duplicates: `projectId`, `leftRecordId`, `rightRecordId`, `signal`, `score`, `status`, `resolution`, `resolvedBy`,
   `resolvedAt`; unique on the ordered record pair so one pair is never queued twice.
2. Variances: `recordId`, `fieldKey`, `registerValue`, `foundValue`, `status`, `resolvedBy`, `resolvedAt`; unique on
   `recordId` plus `fieldKey`.
3. Index both on `projectId` plus `status`, which is how the review screens read them.

## Constraints

- Both tables declare the shared merge columns through `MergeColumns` in the migration that creates them, so a pair
  resolved on one device does not reappear unresolved after merge (FE-SEC-09).
- A resolution records who and when; nothing is auto-resolved and no detection writes a `resolution` (FE-SEC-09, and
  rule 5 of the standard: AI proposes, a person approves).

## Definition of done

- [x] Detecting the same pair twice updates the existing row rather than inserting a second.
- [x] An unresolved queue can be listed by project and status through the index.
- [x] Resolving either kind stores the operator and timestamp and leaves both source records intact.
- [x] Tests: `frontend/test/core/db/tables/duplicates_test.dart` asserts pair uniqueness regardless of argument order
      and resolution recording; `variances_test.dart` covers the register-versus-found round-trip and its unique index.
      Both against an in-memory database, covering their migration steps.
