# 052 — Projects and context tables

**Phase** 04 · Local database  |  **Depends on** [050](050-column-mixins.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The project row with its status, dates, folder name and validated settings, plus the context hierarchy that hangs off
it: the per-project level definitions, the values currently pinned, and saved presets.

## Files

- `frontend/lib/core/db/tables/projects.dart` (new)
- `frontend/lib/core/db/tables/context.dart` (new)

## Steps

1. Projects: `name`, `client`, `status`, `startedAt`, `completedAt`, `folderName`, `settings` as JSON validated on write
   and rejected as a `StorageFailure` when malformed.
2. Index projects on `status` plus `updatedAt`, which is the order the project list reads.
3. Context definitions: `projectId`, `level`, `fieldKey`, `label`; unique on `projectId` plus `level`.
4. Context state: `projectId`, `level`, `value`, `setAt`; setting a level clears every level below it in the same
   transaction.
5. Context presets: `name`, `projectId`, `values` JSON.

## Constraints

- All five tables declare the shared merge columns through `MergeColumns` in the migration that creates them, so a
  project imported from another device merges on `rev` rather than on name (FE-SEC-09).
- `folderName` is stored, never recomputed at read time: renaming a project must not move files on disk.

## Definition of done

- [x] A project can be created, listed by status and updated, with the list query served by the index.
- [x] Setting a higher context level clears every lower level, and no orphan state row survives.
- [x] Malformed settings JSON is refused on write with a recoverable failure, never stored.
- [x] Tests: `frontend/test/core/db/tables/projects_test.dart` covers create, paged list by status and update;
      `context_test.dart` asserts the clear-lower-levels rule and preset round-trip. Both against an in-memory
      database, covering their migration steps.
