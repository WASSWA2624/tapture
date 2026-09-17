# 218 — Apply, record and undo a merge

**Phase** 19 · Bundles and merge  |  **Depends on** [050](../04-data-layer/050-column-mixins.md), [061](../04-data-layer/061-merge-tables.md), [216](216-merge-preview.md), [217](217-conflict-screen.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Applying a confirmed plan: take a snapshot, write every row and file in one transaction, record the merge with its
counts and resolutions, and keep undo available until the snapshot is purged.

## Files

- `frontend/lib/features/merge/domain/merge_apply.dart` (new)
- `frontend/lib/features/merge/presentation/merge_history_screen.dart` (new)
- `frontend/lib/features/merge/domain/merge_undo.dart` (new)

## Contract

```dart
class MergeApply {
  /// Snapshots, applies [plan] in one transaction, writes the merge record, returns its id.
  Future<String> apply(MergePlan plan, {required CancellationToken token});
}

class MergeUndo {
  Future<bool> isAvailable(String mergeId);
  /// Restores rows and files to the snapshot taken before [mergeId].
  Future<void> undo(String mergeId);
}
```

## Steps

1. Snapshot rows and the files the plan will touch before opening the transaction; roll back completely on any failure,
   including a failure while copying files.
2. Store per merge: source device, bundle id, timestamp, counts per category and every resolution with its chooser or
   rule.
3. State the undo deadline in the history entry, and stop offering undo once the snapshot is purged.
4. Restore deleted rows and removed files on undo, not only changed ones.

## Constraints

- One transaction through the helper of 088; a merge is never half-applied (FE-STATE-07).
- The merge record and its resolutions are part of the audit trail, written inside the same transaction (FE-SEC-09).

## Definition of done

- [ ] A failure part-way through leaves the project exactly as it was, files included.
- [ ] History lists every past merge with its counts, source device and resolutions.
- [ ] Undo restores rows and files exactly, including deleted ones, and disappears once its snapshot is purged.
- [ ] Tests: unit tests of `merge_apply.dart` simulating a mid-merge failure and of `merge_undo.dart` comparing project state before the merge with state after undo, plus a widget test of `merge_history_screen.dart` covering the four states.
