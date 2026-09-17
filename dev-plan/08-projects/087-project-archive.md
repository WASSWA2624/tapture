# 087 — Archive, unarchive and delete a project

**Phase** 08 · Projects  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [051](../04-data-layer/051-tombstones-table.md), [086](086-project-edit.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The two ways a project leaves the active list. Archiving hides a finished project from the list and from default
exports and is reversible with nothing lost. Deleting requires the project name typed by hand, writes tombstones, moves
files to the recycle area and stays recoverable until the retention window ends. Neither removes a byte at the moment
the user taps.

## Files

- `frontend/lib/features/projects/presentation/project_archive_action.dart` (new)
- `frontend/lib/features/projects/presentation/project_delete_action.dart` (new)
- `frontend/lib/features/projects/presentation/project_list_screen.dart` (edit)

## Steps

1. Archive sets `ProjectStatus.archived`; the list hides archived projects behind a "Show archived" filter and default
   exports exclude them. Unarchive restores the project with records, files and settings untouched.
2. Delete confirms once through `showAppConfirm` in its destructive form, naming the record and file counts, requiring
   the project name typed, and offering "Export first" in the same dialog — one decision, no dialog chain.
3. Delete sets `ProjectStatus.deleted`, soft-deletes the owned rows and writes exactly one tombstone per entity through
   the helper in `tombstones.dart`, all in one transaction, then moves the project folder into the recycle area.
4. Take the retention window from `AppConstants`; only the purge job removes files, and only after it expires.

## Constraints

- Deletion is a tombstone plus a move; no file is unlinked in the user's request path (FE-SEC-08).
- The destructive confirmation names the consequence and the counts and comes from the one dialog API
  (FE-SIMP-07, FE-CONS-05).

## Definition of done

- [ ] Archiving is reversible and loses nothing; an archived project is absent from the active list and from default
  exports.
- [ ] A mistaken delete is recoverable for the whole retention period, with its files still on disk in the recycle area.
- [ ] Deleting writes exactly one tombstone per deleted entity, inside the delete transaction.
- [ ] Tests: widget tests of both actions covering the typed-name confirmation, the cancel path and the archived filter;
  a test asserting delete writes the tombstones and that no file disappears immediately.

## Out of scope

- The purge job and the recycle-bin screen; this task only writes into the recycle area.
