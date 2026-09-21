# 110 — Data quality: validation, duplicates, conflicts and variance

**Phase** 15 · Data quality  |  **Depends on** [021](../02-foundation/021-result-and-failures.md), [024](../02-foundation/024-hashing-service.md), [054](../04-data-layer/054-records-table.md), [058](../04-data-layer/058-duplicates-table.md), [089](../09-templates/089-field-type-registry.md), [098](../09-templates/098-identity-fields.md), [105](../10-reference-data/105-reference-data.md), [107](../12-capture/107-capture.md), [108](../13-processing/108-processing.md), [109](../14-records/109-records.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Every check that makes the output trustworthy, each with a person in the loop. One validation engine that capture,
review, import and export all call, holding the field rules, the whole-record rules, the export-set rules and the
expression evaluator that `required_when` and the Computed field type both depend on (§12.1, §12.2), and one widget
that renders its issues inline and as a form summary. A stable identity hash stored on the record, the detection
service that ranks duplicate candidates over the specification's five signals, the save-time prompt and side-by-side
comparison behind its four outcomes — override the existing record, keep both and link them, discard the new one, or
merge field by field — and the project-level screen that clears a backlog of pairs one at a time or by confirmed
group. The conflict path, where a field whose independent sources disagree is flagged rather than silently won by one
of them, and the row that lets a person pick a candidate or type their own and say why. Verification mode, where a
project or session confirms existing data rather than creating it and a record arrives prefilled from its register row
with the register's values kept apart from what the field worker found. The variance and missing-item computation that
is the output of a verification exercise, the screen that reads it per record and per project, and one quality summary
answering what still blocks a clean export. Everything here proposes; nothing here resolves itself.

## Files

The engine and its display, shared by every feature:

- `frontend/lib/core/validation/validation_engine.dart` (new)
- `frontend/lib/core/validation/field_validators.dart` (new)
- `frontend/lib/core/validation/field_expression.dart` (new)
- `frontend/lib/core/validation/record_validators.dart` (new)
- `frontend/lib/core/widgets/forms/validation_display.dart` (new)

Quality logic, off the interface:

- `frontend/lib/features/quality/domain/identity_hash.dart` (new)
- `frontend/lib/features/quality/domain/duplicate_detection.dart` (new)
- `frontend/lib/features/quality/domain/duplicate_override.dart` (new)
- `frontend/lib/features/quality/domain/duplicate_link.dart` (new)
- `frontend/lib/features/quality/domain/conflict_detection.dart` (new)
- `frontend/lib/features/quality/domain/verification_prefill.dart` (new)
- `frontend/lib/features/quality/domain/variance_computation.dart` (new)
- `frontend/lib/features/quality/domain/missing_items.dart` (new)

Quality screens:

- `frontend/lib/features/quality/presentation/duplicate_prompt.dart` (new)
- `frontend/lib/features/quality/presentation/duplicate_compare_screen.dart` (new)
- `frontend/lib/features/quality/presentation/duplicate_merge_sheet.dart` (new)
- `frontend/lib/features/quality/presentation/duplicates_screen.dart` (new)
- `frontend/lib/features/quality/presentation/conflict_resolution_row.dart` (new)
- `frontend/lib/features/quality/presentation/verification_mode_toggle.dart` (new)
- `frontend/lib/features/quality/presentation/variance_screen.dart` (new)
- `frontend/lib/features/quality/presentation/quality_summary_screen.dart` (new)

## Contract

```dart
enum Severity { error, warning }

class ValidationIssue {
  const ValidationIssue(this.fieldKey, this.severity, this.message);
  final String? fieldKey;
  final Severity severity;
  final String message;
}

abstract interface class ValidationEngine {
  List<ValidationIssue> validateField(FieldDef field, Object? value, Map<String, Object?> siblings);
  List<ValidationIssue> validateRecord(RecordEntry record, TemplateDef template);
  List<ValidationIssue> validateExportSet(Iterable<RecordEntry> records, TemplateDef template);
}

sealed class FieldExpression {
  static Result<FieldExpression> parse(String source, List<FieldDef> fields);
}

Object? evaluate(FieldExpression expression, Map<String, Object?> values);

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

enum DuplicateChoice { overrideExisting, keepBoth, discardNew, mergeFields }

Future<DuplicateChoice?> showDuplicatePrompt(
  BuildContext context,
  RecordEntry incoming,
  DuplicateCandidate match,
);

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

1. Build the engine first; everything else in the phase blocks or allows through it. Every issue carries a field key, a
   severity and a plain-language message: an error blocks a save, an approval and an export, a warning never does.
   Field rules cover required, type, pattern, length, range, option membership and unit sanity, each driven by the
   field type registry of [089](../09-templates/089-field-type-registry.md) rather than a switch at each call site.
   Requiredness is resolved per record, never read straight off the template: a field is required when its
   `Requiredness` is `required`, or when its `required_when` expression evaluates true for this record's values. Record
   rules also cover the identity fields of [098](../09-templates/098-identity-fields.md) being present, and evidence
   being present where the template demands it. The expression grammar covers comparison, equality, `and`/`or`/`not`
   and arithmetic over other fields of the same record — `qty * unit_cost`, `fault_present == true` — with no
   function calls and no access outside the record; the expression a user types in
   [095](../09-templates/095-field-add-basic.md) does nothing until this evaluator exists, so conditional requiredness
   and computed values arrive with it. Parse against the template's field list so an expression naming a field that
   does not exist fails in that editor rather than at capture time, and yield `null` for anything that cannot be
   evaluated — a missing operand, a type mismatch — never a guess and never an exception: a Computed field with
   incomplete inputs is simply not yet computed (§34).
2. One display widget renders those issues two ways: inline beneath the field a `ValidationIssue` names, and as a
   summary at the head of a long form that says how many issues there are and links to the first field with an error.
   Every screen that edits a record reports problems through it, inside the form scaffold of
   [044](../03-design-system/044-app-form-scaffold.md).
3. Hash the identity values: normalise case, whitespace and punctuation through the normaliser the field type registry
   declares, hash with the service of [024](../02-foundation/024-hashing-service.md), store the result on the record of
   [054](../04-data-layer/054-records-table.md) for fast lookup, and recompute it whenever an identity value is edited.
   Score the five signals — equal identity hash, identical photo hash, near-identical photo hash from the perceptual
   hashing of [108](../13-processing/108-processing.md), the same predefined row of
   [103](../09-templates/103-predefined-rows-import.md) in the same context, and the same name in the same context
   within a short time window — then rank candidates by score and return them. Run detection on save, on table import
   and after a merge, off the save path, so the interface confirms the save immediately. Nothing here merges, discards
   or overrides a record.
4. The save-time prompt offers the four outcomes and shows the differing values with them; dismissing it leaves both
   records and the pair unresolved rather than choosing on the user's behalf. The comparison screen puts the two
   records side by side with their photos, highlights only the fields that differ, and shows photo counts and capture
   details — time, person, context — for both. Override writes the new values onto the existing record, keeps the
   replaced values in history, attaches the new photos and writes an audit entry naming the override; it is reachable
   only from the comparison. The merge sheet decides per field — keep mine, take theirs, or keep both as a note —
   and can carry photos from the discarded side onto the survivor. Keep both writes the pair into the duplicates
   table of [058](../04-data-layer/058-duplicates-table.md) as related, so each record of
   [109](../14-records/109-records.md) carries a badge linking to its counterpart.
5. The duplicates review screen lists a project's unresolved pairs from that table, grouped by the signal and template
   that produced them, with each pair's differing fields in its row so the common case needs no navigation. A bulk
   action applies one choice to the remaining pairs of a group after a confirmation naming the choice and the number of
   records it will change. Resolution goes through the same code path as the save-time prompt, so history, audit
   entries and links are identical however a pair is cleared.
6. Conflict detection compares the OCR, caption, reference-data and barcode candidates for a field after
   normalisation, so `ABB-1234` and `abb 1234` are one value rather than a conflict, and raises a conflict only where
   normalised values genuinely differ — keeping every candidate with its source, confidence and the evidence link of
   [108](../13-processing/108-processing.md). The resolution row shows each candidate beside its source label and its
   evidence, and accepts a typed value matching none of them through the field editor of
   [097](../09-templates/097-field-editor-inline.md). Storing the choice records the value, the source it came from and
   the reason given, then marks the conflict resolved.
7. Verification mode is a toggle in project settings ([086](../08-projects/086-project-edit.md)) and in the session;
   with it on, capture opens the identifier lookup of [107](../12-capture/107-capture.md) before the form. Prefill
   fills every mapped field from the matched reference row through the lookup binding of
   [105](../10-reference-data/105-reference-data.md) and marks the record on-register, keeping the register values in
   their own as-recorded slot so editing the as-found values never overwrites them. An identifier with no matching row
   still creates a record, flagged not-in-register; the lookup never blocks capture.
8. On approval, compare as-recorded with as-found field by field and write the result to the variances table of
   [058](../04-data-layer/058-duplicates-table.md), classifying every mapped field `match`, `changed` or `missing` over
   normalised values so a formatting difference alone is a match. Recompute and rewrite a record's variance rows
   whenever its values change after approval. Compute missing items per project alongside them: register rows that
   produced no record, and checklist rows of [103](../09-templates/103-predefined-rows-import.md) never captured.
9. The variance screen is the deliverable view of a verification exercise: the differences for one record, and the
   differences across a whole project, filtered by `match`, `changed` and `missing`, grouped by context level, each row
   opening into its record. The missing and not-found sets are a filter here, not a separate screen. It assembles from
   [038](../03-design-system/038-app-card.md).
10. The quality summary answers what still blocks a clean export: how many records are invalid, how many duplicate
    pairs and source conflicts are unresolved, and how many records are unreviewed. It takes those counts from the
    engine, the duplicates table and the variance data rather than recounting with query logic of its own, and each
    count opens the screen that clears it — the duplicates screen, the variance screen, the batch review queue of
    111 · Review, or a filtered record list from [109](../14-records/109-records.md).

## Constraints

- Everything under `core/validation/` is pure Dart: no Flutter, Drift or HTTP import (FE-STR-05).
- The evaluator takes no template repository, database or Flutter dependency, so the field editor of
  [095](../09-templates/095-field-add-basic.md), and later export and import, call it directly (FE-CONS-01).
- Parse and evaluation failures come back as `Result` failures, never thrown (FE-CODE-06).
- Errors and warnings differ by icon and wording, not by colour alone (FE-A11Y-05, FE-THEME-05). A warning renders and
  the form stays submittable; only an error blocks (FE-SIMP-08).
- `validation_display.dart` uses tokens only — no literal colour, spacing or text style (FE-THEME-01).
- Detection runs off the save path and never delays the confirmation the interface gives (FE-PERF-02, FE-PERF-08).
- Replaced values and discarded photos are written beside the originals, never over them (FE-SEC-08).
- Every resolution writes an audit row in [051](../04-data-layer/051-tombstones-table.md) naming the choice, both
  record ids and the person (FE-SEC-09).
- The prompt asks one question through the shared dialog service of
  [041](../03-design-system/041-app-dialog-service.md), never its own dialog (FE-CONS-05, FE-SIMP-07).
- A person is always in the loop. Detection, conflict raising and variance computation all propose; nothing here writes
  a resolution that someone did not choose, and no candidate list, conflict or variance is settled by code (rule 5 of
  the standard). A bulk action is never pre-selected and never a default, and applies only to the group its
  confirmation named.

## Definition of done

- [ ] Capture, review, import and export all validate through this engine; no feature holds a second copy of a check.
- [ ] An error blocks a save, an approval and an export; a warning blocks none of the three and leaves the form
      submittable.
- [ ] `required_when` and Computed fields are evaluated through this one evaluator, and a malformed or unsatisfiable
      expression yields `null` plus a typed failure rather than an exception.
- [ ] A record cannot be approved with an empty identity field, or an empty `required_when`-triggered field, when the
      template demands one.
- [ ] Tests: `frontend/test/core/validation/` — table-driven unit tests per rule type over valid and invalid values,
      expression tests covering parsing, evaluation, missing operands and type mismatches, and record-validator tests
      against the template fake, with no Flutter binding.
- [ ] Every screen reports problems the same way; no feature builds its own error text style (FE-CONS-11).
- [ ] The summary names how many issues there are and links to the first field with an error.
- [ ] A change in the issue list is announced to a screen reader (FE-A11Y-07).
- [ ] Tests: golden tests of `validation_display.dart` in light, dark and outdoor themes, plus a widget test of each
      state it renders — none, warnings only, errors only, and mixed.
- [ ] Two records with the same serial collide whatever their spacing, casing or punctuation.
- [ ] Editing an identity value recomputes the stored hash.
- [ ] Detection never delays a save, an import or a merge.
- [ ] A candidate list is a proposal: nothing in the detection path writes to a record.
- [ ] Tests: unit tests of `identity_hash.dart` over spacing, case and punctuation variants, and of
      `duplicate_detection.dart` per signal and over the ranking order, with no Flutter binding.
- [ ] The prompt never appears without the differing values, and any of the four choices can be made without opening
      either record separately.
- [ ] Dismissing the prompt leaves both records and the pair unresolved.
- [ ] Overriding is impossible without passing through the comparison; afterwards history holds the replaced values and
      the audit trail names the override.
- [ ] Merging can keep photos from the discarded side on the survivor; keeping both leaves each record showing a badge
      and a link to its counterpart.
- [ ] Tests: widget tests of `duplicate_prompt.dart`, `duplicate_compare_screen.dart` and `duplicate_merge_sheet.dart`
      including empty and failure states; unit tests of `duplicate_override.dart` asserting history holds the replaced
      values and an audit row is written, and of `duplicate_link.dart`, both with no Flutter binding.
- [ ] A hundred pairs can be cleared without opening each record.
- [ ] A bulk choice applies only to the group it was confirmed for, and the confirmation states how many records
      change.
- [ ] A pair cleared in bulk leaves the same history, audit entries and links as one cleared at save time.
- [ ] Tests: widget test of `duplicates_screen.dart` covering an empty list, a group resolved pair by pair, a group
      resolved in bulk, and its failure state.
- [ ] A formatting difference alone never raises a conflict; a genuine difference always does.
- [ ] A record cannot be approved while a conflict is unresolved, and the block names the field.
- [ ] Resolving records which candidate won, or that the value was typed, together with the reason.
- [ ] Tests: unit tests of `conflict_detection.dart` over the specification example and over normalisation-only
      differences, with no Flutter binding; widget test of `conflict_resolution_row.dart` covering each candidate
      source, a typed value, and its empty and failure states.
- [ ] Verification mode is visible in the status line so no one forgets it is on.
- [ ] A prefilled field shows that it came from the register, and editing it leaves the register value intact.
- [ ] A not-found identifier creates a record flagged not-in-register, and the lookup never blocks capture.
- [ ] Tests: widget test of `verification_mode_toggle.dart` on, off and in its failure state; unit tests of
      `verification_prefill.dart` covering a matched row, an unmatched identifier and the preserved register values,
      with no Flutter binding.
- [ ] The variance table matches the specification example, field for field.
- [ ] Editing an approved record's value rewrites its variance rows and nothing else.
- [ ] Missing items are exportable as their own set.
- [ ] Tests: unit tests of `variance_computation.dart` over changed, matching and empty values, and of
      `missing_items.dart` over a part-captured register and a part-captured checklist, both with no Flutter binding.
- [ ] A project's changed, matching and missing items are readable without opening a record.
- [ ] Tests: widget test of `variance_screen.dart` covering each filter, the grouped list, a record-scoped view, and
      its empty and failure states.
- [ ] Clearing every count on the quality summary leaves the project export-ready, with no further check hidden
      elsewhere.
- [ ] Each count is tappable and lands on the screen that resolves it.
- [ ] Tests: widget test of `quality_summary_screen.dart` covering a clean project, each non-zero count and where it
      navigates, and its failure state.

## Out of scope

- The review screen and the approval gate that enforce these blocks: this task supplies the reasons, 111 · Review acts
  on them.
- Writing missing items and variances into a file: this task exposes both sets, 113 · Export produces the output.
