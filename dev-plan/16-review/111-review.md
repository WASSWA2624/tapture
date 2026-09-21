# 111 — Review: turning proposals into approved data

**Phase** 16 · Review  |  **Depends on** [033](../03-design-system/033-app-page.md), [039](../03-design-system/039-app-status-pill.md), [040](../03-design-system/040-app-empty-state.md), [097](../09-templates/097-field-editor-inline.md), [107](../12-capture/107-capture.md), [108](../13-processing/108-processing.md), [109](../14-records/109-records.md), [110](../15-data-quality/110-data-quality.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The review screen of the specification and every control a person needs on it to turn proposals into approved data:
an attention-first ordering, kept pure in `domain/`, that lifts low-confidence, missing, conflicting and
duplicate-flagged fields above one collapsed group of confident ones; the three controls a review row is built from
— the toggle deciding whether the raw or the refined value is authoritative, the confidence indicator, and the row
that turns a not-detected value into a next step instead of a blank; an evidence viewer that opens the photo region,
document page or transcript passage a value came from, with the region highlighted and its source named; an explicit
verification action, separate from editing, after which processing may not overwrite the value; approve-and-next,
which validates, approves and moves on, plus the batch queue screen that strings it into a session over a filtered
set of records; and re-analysis, which runs processing again over a record whose human work must survive and returns
a diff accepted or declined field by field. A confident record is one tap from approved, and no value becomes
approved data without a person saying so.

## Files

Domain, pure Dart:

- `frontend/lib/features/review/domain/field_ordering.dart` (new)
- `frontend/lib/features/review/domain/approve_record.dart` (new)

Presentation, the screens:

- `frontend/lib/features/review/presentation/review_screen.dart` (new)
- `frontend/lib/features/review/presentation/batch_review_screen.dart` (new)

Presentation, the row controls and actions:

- `frontend/lib/features/review/presentation/raw_refined_toggle.dart` (new)
- `frontend/lib/features/review/presentation/confidence_indicator.dart` (new)
- `frontend/lib/features/review/presentation/not_detected_row.dart` (new)
- `frontend/lib/features/review/presentation/evidence_viewer.dart` (new)
- `frontend/lib/features/review/presentation/verify_action.dart` (new)
- `frontend/lib/features/review/presentation/reanalyse_action.dart` (new)

## Contract

```dart
enum ReviewGroup { needsAttention, confident }

List<(FieldValue, ReviewGroup)> orderForReview(RecordEntry record, TemplateDef template);

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

1. Build `field_ordering.dart` and the review screen on top of it. Show the photos, the fields with their confidence
   band, the context and automatic values, and the caption toggle. On expanded, lay out two panes: evidence on the
   left, fields on the right; the size class comes from the breakpoint helper, never from a `MediaQuery` read inside
   the feature (FE-RESP-02). Order low-confidence, missing, conflicting and duplicate-flagged fields into
   `needsAttention` and collapse everything confident under one expandable group (FE-SIMP-06). The ordering stays
   pure and in `domain/`, so the batch queue built in step 5 and the meeting review of phase 17 · Meetings reuse it
   rather than re-sorting.
2. Build the three row controls. The raw-or-refined toggle works per field and per caption, sets `valueFinal` to the
   chosen side and leaves both sides stored; the most recent choice becomes the project's default for later fields.
   The confidence indicator renders the band that proposal application in 108 computed, showing colour, icon and the
   number together on the shared status pill of 039. The not-detected row offers "type it" and "photograph the
   label" in place, so a value the no-invention guard of 108 refused to invent still has an obvious next action.
3. Build the evidence viewer. Read the evidence rows written by the evidence linking of 108; highlight the bounding
   region on the photo, or show the whole photo where the provider supplied no region. Show the OCR snippet or
   transcript passage beside the image, with the source label. Open through the existing photo viewer of 107 rather
   than building a second viewer (FE-CONS-01).
4. Build the verify action. It sits on the field row beside the inline field editor of 097 and records who verified
   the value and when. One action verifies every confident field of the record at once. A verified value is skipped
   by the proposal application of 108 and offered as a diff by the re-analysis of step 6 instead.
5. Build `approve_record.dart` and the batch review screen. Approval runs the validation engine of 110, then checks
   for unresolved duplicate pairs and unresolved source conflicts, both also from 110. Any failure returns `Blocked`
   naming the field and what must be fixed. On success, move the record through the status lifecycle of 109 and
   return the next unreviewed record in the current filter. The batch screen walks that queue one record at a time
   with a position indicator and a skip, and a back that returns to a record with its edits intact (FE-SIMP-09).
6. Build the re-analyse action. Queue the job through the job queue of 108 and show its progress on the record
   rather than blocking the screen. Present each new value beside the current one, marking which current values are
   verified or manually typed. Write only the changes the user accepts; declining leaves the record exactly as it
   was.

## Constraints

- The screens read through providers and write nothing themselves; edits go through the inline field editor of 097
  (FE-STATE-04).
- AI proposes; a person approves. Nothing here turns a proposal into approved data without an explicit human action,
  and approval is the only path to APPROVED.
- Raw evidence is never destroyed. Choosing the refined side leaves the raw side stored and the choice reversible,
  and re-analysis writes beside verified and manual values rather than over them.
- A band is never signalled by colour alone (FE-A11Y-05, FE-THEME-05).
- These are one row, one pill and one tile from the catalogue, not three new visual idioms (FE-CONS-06).
- Every control is at least 48dp and carries a label (FE-A11Y-01, FE-A11Y-02).

## Definition of done

- [ ] Contract above is implemented exactly, with nothing else made public.
- [ ] A confident record is approvable in one tap, without scrolling past collapsed fields.
- [ ] Every flagged field appears above the confident group, and the confident group starts collapsed.
- [ ] Choosing raw or refined changes only which value is final; neither version is destroyed and the choice
      reverses.
- [ ] A later field in the same project starts on the remembered side.
- [ ] A not-detected field offers typing and photographing in place, and never displays an invented value.
- [ ] Every value carrying an evidence link is checkable in two taps from the review screen.
- [ ] A value whose evidence is a whole photo shows that photo, not an empty highlight.
- [ ] Verifying is distinct from editing: a value can be verified without being changed.
- [ ] A verified value survives reprocessing untouched, and a later proposal for it is offered, never applied.
- [ ] Approval is blocked by a validation error, an unresolved duplicate or an unresolved conflict, and the block
      names the field and the reason.
- [ ] Approving moves straight to the next unreviewed record without returning to a list; forty records can be
      cleared in one pass.
- [ ] Skipping a record and going back to it preserve the edits made on it.
- [ ] A verified or manually typed field is offered as a proposal by re-analysis, never applied silently.
- [ ] Accepting some proposals and declining others leaves exactly the accepted ones written.
- [ ] Tests: widget test of `review_screen.dart` at compact, medium and expanded widths, including its empty and
      failure states.
- [ ] Tests: unit test of `field_ordering.dart` over each flag and their combinations, with no Flutter binding.
- [ ] Tests: widget test of `raw_refined_toggle.dart` over both selections and the remembered default, including its
      empty and failure states.
- [ ] Tests: widget test of `confidence_indicator.dart` over all three bands, asserting icon and number are both
      present, including its empty and failure states.
- [ ] Tests: widget test of `not_detected_row.dart` over both affordances, including its empty and failure states.
- [ ] Tests: widget test of `evidence_viewer.dart` covering a bounded region, the whole-photo fallback, a transcript
      passage, and its empty and failure states.
- [ ] Tests: widget test of `verify_action.dart` covering single and bulk verification, the recorded verifier, and
      its empty and failure states.
- [ ] Tests: unit tests of `approve_record.dart` over each block condition and the clean path, with no Flutter
      binding.
- [ ] Tests: widget test of `batch_review_screen.dart` covering skip, back, the end of the queue, and its empty and
      failure states.
- [ ] Tests: widget test of `reanalyse_action.dart` covering the diff, partial acceptance, a full decline, and its
      empty and failure states, including one asserting a verified field is offered rather than applied.

## Out of scope

- Resolving duplicates and source conflicts, and rendering validation issues. Approval blocks on all three and sends
  the user to the screens of 110 · Data quality rather than growing its own.
- The processing pipeline itself. Re-analysis queues a job and renders the diff; extraction, parsing and proposal
  application stay in 108 · Processing.
- Meeting minutes review, which reuses this ordering and this approval path but belongs to 112 · Meetings.
