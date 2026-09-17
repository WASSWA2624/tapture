# 056 — Reference dataset tables

**Phase** 04 · Local database  |  **Depends on** [052](052-projects-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Imported lookup tables and their rows, queryable by key and by normalised name so field lookup and fuzzy matching are
index-served.

## Files

- `frontend/lib/core/db/tables/reference.dart` (new)

## Steps

1. Datasets: `name`, `scope` as global or project, `projectId` nullable, `keyColumn`, `columns` JSON, `sourceFile`,
   `importedAt`, `rowCount`.
2. Rows: `datasetId`, `keyValue`, `keyNormalised`, `values` JSON.
3. Unique index on `datasetId` plus `keyValue`; index on `datasetId` plus `keyNormalised` for fuzzy matching.
4. Compute `keyNormalised` on write — case-folded, accent-stripped, whitespace-collapsed — never at query time.

## Constraints

- Both tables declare the shared merge columns through `MergeColumns` in the migration that creates them, so a dataset
  imported on two devices merges rather than duplicating (FE-SEC-09).
- Imported cell text is stored as data and never interpolated into a query or a provider instruction (FE-SEC-05).

## Definition of done

- [ ] A dataset of 10,000 rows imports and a key lookup stays within the search budget of FE-PERF-01.
- [ ] Re-importing the same source file updates rows in place instead of creating a second dataset.
- [ ] Tests: `frontend/test/core/db/tables/reference_test.dart` covers dataset insert, keyed lookup, normalised lookup
      and re-import, against an in-memory database, covering the migration step.
