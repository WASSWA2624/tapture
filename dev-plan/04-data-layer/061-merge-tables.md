# 061 — Merge session, conflict and version vector tables

**Phase** 04 · Local database  |  **Depends on** [050](050-column-mixins.md), [054](054-records-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Everything merge persists: the bundle import session with enough state to undo it, the per-field conflicts a person
resolves, and the version vector recording the highest revision seen per entity per device so an incoming entity is
classified without scanning history.

## Files

- `frontend/lib/core/db/tables/merge.dart` (new)
- `frontend/lib/core/db/tables/sync_state.dart` (new)

## Contract

```dart
enum VectorRelation { dominates, dominated, concurrent, equal }

VectorRelation compareVectors(Map<String, int> mine, Map<String, int> theirs);
```

## Steps

1. Sessions: `bundleName`, `sourceDevice`, `importedAt`, `counts` JSON, `status`, `undoSnapshotPath`.
2. Conflicts: `sessionId`, `entityType`, `entityId`, `fieldKey`, `mineValue`, `theirsValue`, `mineMeta`, `theirsMeta`,
   `resolution`, `resolvedAt`, `resolvedBy`; index on `sessionId` plus `resolution` for the unresolved queue.
3. Version vector: `entityType`, `entityId`, `deviceId`, `rev`; unique on the triple, and a query returning the whole
   vector for one entity in one read.
4. Implement `compareVectors` covering all four relations, with concurrency reported rather than resolved.

## Constraints

- All three tables declare the shared merge columns through `MergeColumns` in the migration that creates them
  (FE-SEC-09).
- `mineValue` and `theirsValue` are recorded verbatim and never normalised: the undo path replays them (FE-SEC-08).
- A conflict is only ever resolved by a recorded operator decision; merge never picks a winner for a concurrent pair.

## Definition of done

- [x] Any incoming entity is classified as dominating, dominated, concurrent or equal from one vector read.
- [x] A session retains its undo snapshot path and its unresolved conflicts survive an app restart.
- [x] Resolving a conflict records the operator and timestamp and bumps the entity's vector entry.
- [x] Tests: `frontend/test/core/db/tables/merge_test.dart` covers session insert, the unresolved-conflict query and
      resolution recording; `sync_state_test.dart` asserts the unique triple and all four `compareVectors` outcomes.
      Both against an in-memory database, covering their migration steps.
