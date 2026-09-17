# 174 — Duplicates review screen

**Phase** 15 · Data quality  |  **Depends on** [163](../14-records/163-records-list.md), [173](173-duplicate-prompt.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Project-level list of unresolved pairs from the duplicates table, offering the same four outcomes as the save-time
prompt plus one confirmed decision applied across a group.

## Files

- `frontend/lib/features/quality/presentation/duplicates_screen.dart` (new)

## Steps

1. Group pairs by the signal and template that produced them, and show each pair's differing fields in its row, so the
   common case needs no navigation.
2. A bulk action applies one choice to the remaining pairs of a group after a confirmation naming the choice and the
   number of records it will change. It is never pre-selected and never a default.
3. Resolve through the same code path as 321, so history, audit entries and links are identical however a pair is
   cleared.

## Definition of done

- [ ] A hundred pairs can be cleared without opening each record.
- [ ] A bulk choice applies only to the group it was confirmed for, and the confirmation states how many records change.
- [ ] Tests: widget test of `duplicates_screen.dart` covering an empty list, a group resolved pair by pair, a group
      resolved in bulk, and its failure state.
