# 213 — Entity and field merge with automatic settlement

**Phase** 19 · Bundles and merge  |  **Depends on** [050](../04-data-layer/050-column-mixins.md), [054](../04-data-layer/054-records-table.md), [212](212-version-vector-service.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The merge engine that turns a validated bundle into a plan: each entity classified as insert, fast-forward, ignore or
concurrent; each concurrent record compared field by field; and each field difference settled by the four automatic
rules or escalated to a conflict. It decides; it writes nothing.

## Files

- `frontend/lib/features/merge/domain/merge_entities.dart` (new)
- `frontend/lib/features/merge/domain/merge_fields.dart` (new)
- `frontend/lib/features/merge/domain/merge_rules.dart` (new)

## Contract

```dart
enum EntityDecision { insert, fastForward, ignore, concurrent }

class MergePlan {
  const MergePlan(this.inserts, this.updates, this.deletes, this.conflicts, this.autoResolutions);
  final List<FieldConflict> conflicts;
  final List<AutoResolution> autoResolutions; // each names the rule that decided it
}

enum SettlementRule { verifiedBeatsUnverified, scannedBeatsInferred, valueBeatsUntouchedEmpty, none }

class MergeRules {
  SettlementRule settle(FieldSide mine, FieldSide theirs);
}
```

## Steps

1. Process in dependency order: project, templates, reference data, records, record fields, files.
2. Classify each entity from its version vectors: absent locally is `insert`, dominated locally is `fastForward`,
   dominating locally is `ignore`, otherwise `concurrent`.
3. For a concurrent record, compare field by field: a change on one side only applies, identical values are not a
   conflict, differing values go to the rules.
4. Apply the four rules in order — verified beats unverified, a barcode or reference value beats an inferred one, a
   non-empty value beats a never-edited empty one, otherwise conflict — and record an `AutoResolution` naming the rule.

## Constraints

- The plan is a value: nothing here opens a transaction or touches a table (FE-STR-05).
- Every automatic settlement is recorded with its rule, ready for the audit trail (FE-SEC-09).

## Definition of done

- [ ] Planning the same bundle twice over an unchanged project produces an identical plan with nothing to apply.
- [ ] Every automatic decision carries the rule that made it, and the fall-through produces a conflict rather than a guess.
- [ ] One-sided field changes apply, identical values raise nothing, differing values escalate.
- [ ] Tests: unit tests of `merge_entities.dart` over all four decisions and dependency ordering, `merge_fields.dart` over the three field cases, and `merge_rules.dart` per rule plus the fall-through, with no Flutter binding.
