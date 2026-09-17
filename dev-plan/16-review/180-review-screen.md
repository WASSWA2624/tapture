# 180 — Review screen and attention-first ordering

**Phase** 16 · Review  |  **Depends on** [033](../03-design-system/033-app-page.md), [040](../03-design-system/040-app-empty-state.md), [151](../13-processing/151-proposal-application.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The review screen of the specification, with its fields already sorted so the ones needing attention sit at the top
and the confident ones are collapsed behind one group. A confident record is one tap from approved.

## Files

- `frontend/lib/features/review/presentation/review_screen.dart` (new)
- `frontend/lib/features/review/domain/field_ordering.dart` (new)

## Contract

```dart
enum ReviewGroup { needsAttention, confident }

List<(FieldValue, ReviewGroup)> orderForReview(RecordEntry record, TemplateDef template);
```

## Steps

1. Show the photos, the fields with their confidence band, the context and automatic values, and the caption toggle.
2. On expanded, lay out two panes: evidence on the left, fields on the right. The size class comes from the breakpoint
   helper, never from a `MediaQuery` read inside the feature (FE-RESP-02).
3. Order low-confidence, missing, conflicting and duplicate-flagged fields into `needsAttention`; collapse everything
   confident under one expandable group (FE-SIMP-06).
4. Keep the ordering pure and in `domain/`, so the batch queue of 342 and the meeting review of 358 reuse it rather
   than re-sorting.

## Constraints

- The screen reads through providers and writes nothing itself; edits go through the inline field editor of 170
  (FE-STATE-04).

## Definition of done

- [ ] A confident record is approvable in one tap, without scrolling past collapsed fields.
- [ ] Every flagged field appears above the confident group, and the confident group starts collapsed.
- [ ] Tests: widget test of `review_screen.dart` at compact, medium and expanded widths; unit test of
      `field_ordering.dart` over each flag and their combinations, with no Flutter binding.
