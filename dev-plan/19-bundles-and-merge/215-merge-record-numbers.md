# 215 — Relabel colliding record numbers

**Phase** 19 · Bundles and merge  |  **Depends on** [135](../12-capture/135-auto-fields.md), [213](213-merge-entity-level.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two devices working offline both allocate record number 41. After a merge, human-facing numbers are unique again and no
identifier, reference or file path has moved.

## Files

- `frontend/lib/features/merge/domain/merge_numbering.dart` (new)

## Contract

```dart
class MergeNumbering {
  /// New numbers for incoming records whose number is already taken; keys are record UUIDs.
  Map<String, String> relabel(Iterable<IncomingRecord> incoming, Set<String> takenNumbers);
}
```

## Steps

1. Continue the project's sequence from 250 rather than inventing a suffix, so relabelled records read like the rest.
2. Keep the number the record arrived with in its history, so a field note referring to the old number is still
   traceable.
3. Never renumber a record that already exists on this device; only the incoming side moves.

## Constraints

- Identity is the UUID: nothing here touches a foreign key, a photo filename or a manifest entry (FE-STATE-06).

## Definition of done

- [ ] After merging two projects that each allocated the same numbers, every record number in the project is unique.
- [ ] No reference breaks, and each relabelled record still shows the number it arrived with.
- [ ] Tests: unit tests of `merge_numbering.dart` over full collision, partial collision and no collision, asserting local records keep their numbers, with no Flutter binding.
