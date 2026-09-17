# 060 — Exports table

**Phase** 04 · Local database  |  **Depends on** [052](052-projects-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Export history: what was produced, from which records, with which options, and the hash of the file that left the
device.

## Files

- `frontend/lib/core/db/tables/exports.dart` (new)

## Steps

1. Columns: `projectId`, `version`, `formats`, `filters` JSON, `recordCount`, `filePath`, `fileHash`, `createdBy`.
2. Increment `version` per project so successive exports are distinguishable without reading the filesystem.
3. Index on `projectId` plus `createdAt` for the export history list.

## Constraints

- The table declares the shared merge columns through `MergeColumns` in the migration that creates it (FE-SEC-09).
- `fileHash` and `filePath` are written once when the export completes; a re-export creates a new row (FE-SEC-08).
- `filters` records the query, never the exported values.

## Definition of done

- [ ] Completing an export writes exactly one row, and an abandoned export writes none.
- [ ] The history for a project lists newest first through the index.
- [ ] Tests: `frontend/test/core/db/tables/exports_test.dart` covers per-project version increment, history ordering and
      the absence of a row after a failed export, against an in-memory database, covering the migration step.
