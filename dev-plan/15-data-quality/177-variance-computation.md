# 177 — Variance and missing-item computation

**Phase** 15 · Data quality  |  **Depends on** [058](../04-data-layer/058-duplicates-table.md), [103](../09-templates/103-predefined-rows-import.md), [176](176-verification-mode.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On approval, compare as-recorded with as-found field by field and write the result to the variances table. Alongside
it, the set of register entries never found and checklist rows never captured. Together these are the output of a
verification exercise.

## Files

- `frontend/lib/features/quality/domain/variance_computation.dart` (new)
- `frontend/lib/features/quality/domain/missing_items.dart` (new)

## Contract

```dart
enum VarianceStatus { match, changed, missing }

class FieldVariance {
  const FieldVariance(this.fieldKey, this.recorded, this.found, this.status);
  final String fieldKey;
  final Object? recorded;
  final Object? found;
  final VarianceStatus status;
}

class MissingItems {
  const MissingItems(this.registerNotFound, this.checklistNotCaptured);
  final List<String> registerNotFound;
  final List<String> checklistNotCaptured;
}
```

## Steps

1. Classify every mapped field `match`, `changed` or `missing`, comparing normalised values so a formatting difference
   alone is a match.
2. Recompute and rewrite a record's variance rows whenever its values change after approval.
3. Compute missing items per project: register rows that produced no record (330), and checklist rows never captured
   (184).

## Definition of done

- [ ] The variance table matches the specification example, field for field.
- [ ] Editing an approved record's value rewrites its variance rows and nothing else.
- [ ] Missing items are exportable as their own set.
- [ ] Tests: unit tests of `variance_computation.dart` over changed, matching and empty values, and of
      `missing_items.dart` over a part-captured register and a part-captured checklist, both with no Flutter binding.
