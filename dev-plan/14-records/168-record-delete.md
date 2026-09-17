# 168 — Delete, recycle bin and retention purge

**Phase** 14 · Records  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [051](../04-data-layer/051-tombstones-table.md), [068](../05-file-storage/068-thumbnail-cache.md), [162](162-record-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Deleting writes a tombstone and hides the record, with undo from the snackbar; the recycle bin lists what is deleted
with the days it has left and restores it whole; and the purge job removes rows and files for good once the retention
window has passed.

## Files

- `frontend/lib/features/records/presentation/record_delete_action.dart` (new)
- `frontend/lib/features/records/presentation/recycle_bin_screen.dart` (new)
- `frontend/lib/features/records/domain/purge_job.dart` (new)

## Steps

1. Confirm through the dialog service (task 041), write the tombstone (task 051), hide from lists, offer undo in the
   snackbar.
2. The bin shows remaining days per item and restores in one action; empty-now sits behind a strong confirmation.
3. The purge runs on launch, takes only rows past the window, removes their files through the cleanup path of task
   123, logs the counts, and never purges a tombstone a merge still needs.

## Constraints

- Deletion is a tombstone; files disappear only in the purge, after the window (FE-SEC-08).

## Definition of done

- [ ] Files are retained until purge, so restore is always complete.
- [ ] A tombstone a merge still needs is never purged, and nothing leaves storage without an explicit action or an
      expired window.
- [ ] Tests: test of delete, undo and restore; test that a recent deletion survives a purge run and an unmerged
      tombstone is skipped; widget test of `recycle_bin_screen.dart`, including its empty and failure states.
