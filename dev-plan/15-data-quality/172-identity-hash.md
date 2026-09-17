# 172 — Identity hash and duplicate detection

**Phase** 15 · Data quality  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [054](../04-data-layer/054-records-table.md), [098](../09-templates/098-identity-fields.md), [145](../13-processing/145-ocr-result-store.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A stable hash over a record's identity values, stored on the record for fast lookup, and the service that combines it
with the specification's other duplicate signals to rank candidate matches. The service only ever proposes; every
resolution is a person's choice in 321.

## Files

- `frontend/lib/features/quality/domain/identity_hash.dart` (new)
- `frontend/lib/features/quality/domain/duplicate_detection.dart` (new)

## Contract

```dart
String identityHash(TemplateDef template, Map<String, Object?> values);

enum DuplicateSignal { identity, samePhoto, nearPhoto, predefinedRow, nameContextTime }

class DuplicateCandidate {
  const DuplicateCandidate(this.recordId, this.score, this.signals);
  final String recordId;
  final double score;
  final Set<DuplicateSignal> signals;
}

abstract interface class DuplicateDetection {
  Future<List<DuplicateCandidate>> candidatesFor(RecordEntry record);
}
```

## Steps

1. Normalise case, whitespace and punctuation before hashing through 032, and recompute the stored hash whenever an
   identity value is edited.
2. Score the five signals: equal identity hash, identical photo hash, near-identical photo hash (268), the same
   predefined row in the same context, and the same name in the same context within a short time window.
3. Rank candidates by score and return them. Nothing here merges, discards or overrides a record.
4. Run detection on save, on table import and after a merge, off the save path, so the interface confirms the save
   immediately (FE-PERF-02, FE-PERF-08).

## Definition of done

- [ ] Two records with the same serial collide whatever their spacing, casing or punctuation.
- [ ] Detection never delays a save, an import or a merge.
- [ ] A candidate list is a proposal: no code in this task writes to a record.
- [ ] Tests: unit tests of `identity_hash.dart` over spacing, case and punctuation variants, and of
      `duplicate_detection.dart` per signal and over the ranking order, with no Flutter binding.
