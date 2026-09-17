# 054 — Records and record fields tables

**Phase** 04 · Local database  |  **Depends on** [050](050-column-mixins.md), [053](053-templates-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The central record row with its status, context snapshot and identity hash, and the one-row-per-field table beneath it
carrying raw, refined and final values with their provenance. Raw and refined are separate columns from the first
migration.

## Files

- `frontend/lib/core/db/tables/records.dart` (new)
- `frontend/lib/core/db/tables/record_fields.dart` (new)

## Steps

1. Records: `projectId`, `templateId`, `templateRowId` nullable, `status`, `processingMode`, `contextJson`,
   `identityHash`, `source`, `capturedAt`, `capturedBy`, `gpsLat`, `gpsLon`, `approvedAt`, `approvedBy`.
2. Index records on `projectId` plus `status`, on `identityHash`, on `capturedAt` and on `templateId`.
3. Record fields: `recordId`, `fieldKey`, `valueRaw`, `valueRefined`, `valueFinal`, `confidence`, `source`, `verified`,
   `verifiedBy`, `verifiedAt`.
4. Unique index on `recordId` plus `fieldKey`; index on `fieldKey` plus `valueFinal` for search.
5. Store `contextJson` as the values in force at capture, never a live join, so a later context correction cannot
   rewrite what was captured.

## Constraints

- Both tables declare the shared merge columns through `MergeColumns` in the migration that creates them; `identityHash`
  plus the merge columns are what let two devices recognise the same record (FE-SEC-09).
- `valueRaw` is written once at creation and never updated; refinement writes `valueRefined` and approval writes
  `valueFinal` (FE-SEC-08, enforced by task 018).
- Every value change goes through the audit append helper of task 051 in the same transaction (FE-SEC-09).

## Definition of done

- [ ] Listing a project's records by status is paged and served by the index, never by a full scan.
- [ ] Writing a refined or final value leaves `valueRaw` byte-identical; a second write to `valueRaw` is refused.
- [ ] A duplicate `fieldKey` for one record is refused by the unique index.
- [ ] Tests: `frontend/test/core/db/tables/records_test.dart` covers paged listing by project and status and lookup by
      `identityHash`; `record_fields_test.dart` asserts raw is untouched by refinement and that the unique index holds.
      Both against an in-memory database, covering their migration steps.
