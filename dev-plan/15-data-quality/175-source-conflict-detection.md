# 175 — Source conflicts: detect and resolve

**Phase** 15 · Data quality  |  **Depends on** [097](../09-templates/097-field-editor-inline.md), [151](../13-processing/151-proposal-application.md), [155](../13-processing/155-evidence-linking.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A field whose independent sources disagree is flagged rather than silently won by one of them, and the row that lets a
person pick a candidate or type their own and say why. An unresolved conflict blocks approval in 342.

## Files

- `frontend/lib/features/quality/domain/conflict_detection.dart` (new)
- `frontend/lib/features/quality/presentation/conflict_resolution_row.dart` (new)

## Contract

```dart
class ValueCandidate {
  const ValueCandidate(this.source, this.value, this.confidence, this.evidenceId);
  final ValueSource source;
  final Object? value;
  final double confidence;
  final String? evidenceId;
}

class FieldConflict {
  const FieldConflict(this.fieldKey, this.candidates);
  final String fieldKey;
  final List<ValueCandidate> candidates;
}
```

## Steps

1. Compare the OCR, caption, reference-data and barcode candidates for a field after normalisation, so `ABB-1234` and
   `abb 1234` are one value rather than a conflict.
2. Raise a conflict only where normalised values genuinely differ, keeping every candidate with its source, confidence
   and evidence link (287).
3. The row shows each candidate beside its source label and its evidence, and accepts a typed value matching none of
   them through the inline field editor of 170.
4. Store the chosen value, the source it came from and the reason given, then mark the conflict resolved.

## Definition of done

- [ ] A formatting difference alone never raises a conflict; a genuine difference always does.
- [ ] A record cannot be approved while a conflict is unresolved, and the block names the field.
- [ ] Resolving records which candidate won, or that the value was typed, together with the reason.
- [ ] Tests: unit tests of `conflict_detection.dart` over the specification example and over normalisation-only
      differences, with no Flutter binding; widget test of `conflict_resolution_row.dart` covering each candidate
      source, a typed value, and its empty and failure states.
