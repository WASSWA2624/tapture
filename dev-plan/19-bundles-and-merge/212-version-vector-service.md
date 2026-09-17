# 212 — Version vectors and tombstone propagation

**Phase** 19 · Bundles and merge  |  **Depends on** [051](../04-data-layer/051-tombstones-table.md), [061](../04-data-layer/061-merge-tables.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The primitives every merge decision rests on: a version vector per entity, maintained on each local write and comparable
as dominates, dominated or concurrent; and tombstone handling that carries deletions between devices without ever
resurrecting data silently.

## Files

- `frontend/lib/features/merge/domain/version_vectors.dart` (new)
- `frontend/lib/features/merge/domain/tombstone_merge.dart` (new)

## Contract

```dart
enum VectorRelation { equal, dominates, dominated, concurrent }

class VersionVector {
  const VersionVector(this.counters);
  final Map<String, int> counters; // deviceId -> counter
  VersionVector increment(String deviceId);
  VersionVector merge(VersionVector other);
  VectorRelation compareTo(VersionVector other);
}

enum TombstoneOutcome { applyDelete, ignoreDelete, conflictEditAfterDelete }
```

## Steps

1. Increment the local device's counter on every write to a mergeable entity; an empty vector compares as dominated by
   any non-empty one.
2. Resolve a delete against an older edit as `applyDelete`; an edit whose vector post-dates the delete becomes
   `conflictEditAfterDelete` rather than a silent resurrection.
3. Keep tombstones after they are applied, so a third device receiving the same delete twice reaches the same result.

## Constraints

- Both files are pure Dart with no Drift import; the tables of 110 and 089 are reached through their repositories
  (FE-STR-05, FE-STATE-05).

## Definition of done

- [ ] Every pair of vectors classifies as exactly one `VectorRelation`, including empty vectors on either side.
- [ ] No merge ever brings back an entity that was deliberately deleted later.
- [ ] An edit made after a delete surfaces as a conflict for a person to settle.
- [ ] Tests: unit tests of `version_vectors.dart` over all four relations and empty vectors, and of `tombstone_merge.dart` over both orderings and a repeated delete, with no Flutter binding.
