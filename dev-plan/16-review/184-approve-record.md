# 184 — Approve and next, and the batch queue

**Phase** 16 · Review  |  **Depends on** [162](../14-records/162-record-model.md), [170](../15-data-quality/170-validation-engine.md), [180](180-review-screen.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The primary review action — validate, approve, move to the next record needing review — and the queue screen that
strings it into a session over a filtered set of records.

## Files

- `frontend/lib/features/review/domain/approve_record.dart` (new)
- `frontend/lib/features/review/presentation/batch_review_screen.dart` (new)

## Contract

```dart
sealed class ApprovalOutcome {}

class Approved extends ApprovalOutcome {
  Approved(this.nextRecordId);
  final String? nextRecordId;
}

class Blocked extends ApprovalOutcome {
  Blocked(this.reasons);
  final List<ValidationIssue> reasons;
}

Future<ApprovalOutcome> approveAndNext(String recordId, RecordFilter filter);
```

## Steps

1. Approval runs the engine of 315, then checks for unresolved duplicate pairs (320) and unresolved source conflicts
   (327). Any failure returns `Blocked` naming the field and what must be fixed.
2. On success, move the record through the lifecycle of 301 and return the next unreviewed record in the current
   filter.
3. The batch screen walks that queue one record at a time with a position indicator and a skip, and a back that
   returns to a record with its edits intact (FE-SIMP-09).

## Definition of done

- [ ] Approval is blocked by a validation error, an unresolved duplicate or an unresolved conflict, and the block names
      the field and the reason.
- [ ] Approving moves straight to the next unreviewed record without returning to a list; forty records can be cleared
      in one pass.
- [ ] Skipping a record and going back to it preserve the edits made on it.
- [ ] Tests: unit tests of `approve_record.dart` over each block condition and the clean path, with no Flutter binding;
      widget test of `batch_review_screen.dart` covering skip, back, the end of the queue, and its empty and failure
      states.
