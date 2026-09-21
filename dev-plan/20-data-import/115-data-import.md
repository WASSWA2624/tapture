# 115 — Data import: continue an inventory someone else started

**Phase** 20 · Data import  |  **Depends on** [038](../03-design-system/038-app-card.md), [041](../03-design-system/041-app-dialog-service.md), [050](../04-data-layer/050-column-mixins.md), [071](../05-file-storage/071-file-validation.md), [088](../09-templates/088-template-model.md), [102](../09-templates/102-xlsx-mapping-screen.md), [109](../14-records/109-records.md), [110](../15-data-quality/110-data-quality.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Everything needed to continue an inventory someone else started. One entry point that takes any file the app accepts —
a bundle, a spreadsheet, a reference dataset or a template — validates it through the shared file gate, detects its
kind from that result rather than from its extension, explains each destination in one line and routes it to the flow
that owns it; for a spreadsheet, the one question that changes everything downstream, whether its rows are records to
hold or the register to verify against, with the register answer feeding the verification prefill of 110 · Data quality
instead of creating anything; the column mapping screen of the template phase driven to its second purpose, mapping a
workbook's columns onto an existing template's fields, with identity fields mandatory before the flow continues and the
first rows shown as they will be read; the runner that turns mapped rows into records with source `IMPORTED_TABLE`,
validating per row, collecting failures with their row numbers and reasons rather than aborting, settling every match
against an existing record by an operator choice that can be applied to the rest of the run, and inserting in batches
inside one transaction with visible progress; and the summary of what an import actually did — created, updated,
skipped and failed with a reason per row — which exports the skipped and failed rows as a list to correct and bring
back, and retries only the failures. The Projects empty state offers import again once all of this works.

## Files

Import logic, off the interface:

- `frontend/lib/features/import/domain/record_import.dart` (new)
- `frontend/lib/features/import/domain/import_duplicates.dart` (new)

Import screens:

- `frontend/lib/features/import/presentation/import_screen.dart` (new)
- `frontend/lib/features/import/presentation/import_purpose_step.dart` (new)
- `frontend/lib/features/import/presentation/record_mapping_screen.dart` (new)
- `frontend/lib/features/import/presentation/import_summary_screen.dart` (new)

Where import returns:

- `frontend/lib/features/projects/presentation/project_list_screen.dart` (changed)

## Contract

```dart
enum ImportDuplicateChoice { keepExisting, replace, merge }

class RecordImportResult {
  const RecordImportResult(this.created, this.updated, this.skipped, this.failures);
  final int created, updated, skipped;
  final List<RowFailure> failures; // row index and reason
}

class RecordImport {
  Stream<ImportProgress> run(RecordMapping mapping, {required CancellationToken token});
}
```

## Steps

1. Build the entry screen first, because everything else here hangs off it. One screen takes the chosen file, passes it
   through the validation gate of [071](../05-file-storage/071-file-validation.md), and detects its kind from that
   result rather than from the extension alone. Explain each destination in one line, then apply the detected kind
   rather than asking about it: a bundle goes to the merge flow of 114 · Bundles and merge, a reference dataset to the
   importers of 105 · Reference data, a template to the mapping screen of
   [102](../09-templates/102-xlsx-mapping-screen.md), and a spreadsheet of rows to the purpose step below. An
   unsupported or corrupt file is refused here, with its reason, before any flow starts.
2. Ask the purpose for spreadsheets only; a bundle and a template have no ambiguity to resolve. Records to hold go on
   to the mapping screen; the register to verify against feeds the verification prefill of
   [110](../15-data-quality/110-data-quality.md) instead of creating records, so the verification exercise it belongs
   to works with those rows immediately.
3. Drive the mapping onto an existing template. Preselect each mapping by header name against the target template's
   field keys and labels, leaving the operator to confirm every one. Block continuing until every field the template of
   [088](../09-templates/088-template-model.md) marks as identity is mapped, and say which one is missing. Show the
   first rows as they would be interpreted, so a wrong mapping is visible before the import runs. Reuse the workbook
   reader, header detection and type inference of [101](../09-templates/101-xlsx-read-workbook.md) unchanged.
4. Turn the mapped rows into records. Validate per row through the validation engine of
   [110](../15-data-quality/110-data-quality.md) and collect failures with their row number and reason rather than
   aborting the import. Compare each incoming row against existing records through that phase's duplicate detection
   before inserting it, and offer keep existing, replace and merge per match, with an apply-to-all option for the rest
   of the run. Insert in batches inside one transaction, over the merge columns of
   [050](../04-data-layer/050-column-mixins.md), writing each record of [109](../14-records/109-records.md) with source
   `IMPORTED_TABLE` and reporting progress per batch.
5. Finish with the summary. Group rows by outcome — created, updated, skipped and failed — each identified by its
   spreadsheet row number, assembled from [038](../03-design-system/038-app-card.md). Export the skipped and failed
   rows as a file the operator can correct and re-import. Retry re-runs only the failed rows through the same mapping,
   without duplicating the successful ones.
6. Put import back on the Projects list now that it exists. The control task 315 hid until this flow was built returns
   with `Copy.projectsImport`, so the empty state names an action that works.

## Constraints

- Reuse the workbook reader, header detection and type inference of
  [101](../09-templates/101-xlsx-read-workbook.md) and the mapping interface of
  [102](../09-templates/102-xlsx-mapping-screen.md) unchanged; a second copy of a reader, a header detector or an
  inference rule is a defect, not a shortcut (FE-CONS-02, FE-STR-09).
- Import reuses the duplicate detection of [110](../15-data-quality/110-data-quality.md) and defines no similarity
  logic of its own; only its own resolution choice is local. `ImportDuplicateChoice` names what an import does with a
  match and neither replaces nor shadows that phase's `DuplicateChoice` (FE-CONS-01, FE-CONS-02).
- Rows are validated through the engine of [110](../15-data-quality/110-data-quality.md), never through a check written
  here (FE-CONS-01).
- One decision per step (FE-SIMP-07); a detected kind is applied rather than asked about (FE-SIMP-05).
- The chosen file is untrusted until validated, and its text — cell values, headers and file name alike — is data,
  never instruction (FE-SEC-05, FE-SEC-06).
- The duplicate choice is asked through the shared dialog service of
  [041](../03-design-system/041-app-dialog-service.md), never a dialog of this phase's own (FE-CONS-05).
- Batch inserts run off the UI thread; ten thousand rows must not stall a frame (FE-PERF-02, FE-PERF-08).
- Plain language for every reason: a validation message names the field and what was expected (FE-SIMP-10).

## Definition of done

- [ ] A user never has to know which importer to pick; each supported kind reaches its flow from this one screen.
- [ ] A kind is detected from the validated file rather than from its extension, and an unsupported or corrupt file is
      refused here with a reason, before any flow starts.
- [ ] The purpose question is asked for spreadsheets and for nothing else.
- [ ] After a register import, the verification flow works immediately with those rows.
- [ ] Tests: widget tests of `import_screen.dart` over each detected kind, an unsupported file and the four states.
- [ ] Tests: widget test of `import_purpose_step.dart` asserting both destinations.
- [ ] The same mapping interface serves both template creation and record import, with no duplicated reader or
      inference.
- [ ] Mappings are preselected by header name and every one stays the operator's to confirm or change.
- [ ] The flow cannot continue while an identity field is unmapped, and names the field that is missing.
- [ ] The first rows are shown as they would be interpreted, before the import runs.
- [ ] Tests: widget test of `record_mapping_screen.dart` covering preselected mappings, a blocked continue with an
      unmapped identity field, and the four states.
- [ ] Ten thousand rows import without freezing the interface, with visible progress.
- [ ] Invalid rows are collected with their row number and reason, and the valid rows still import.
- [ ] Records created here carry source `IMPORTED_TABLE` and land in one transaction.
- [ ] No import silently overwrites an existing record; every match is settled by a choice, which can be applied to
      all.
- [ ] This phase holds no second detector and no second `DuplicateChoice`: similarity comes from 110 · Data quality and
      only the import outcome is declared here.
- [ ] Tests: unit tests of `record_import.dart` over a fixture containing invalid rows, with no Flutter binding.
- [ ] Tests: unit tests of `import_duplicates.dart` over each `ImportDuplicateChoice` plus apply-to-all, with no
      Flutter binding.
- [ ] Every skipped or failed row is explained with its row number and reason, and the set is exportable as a list.
- [ ] Retrying failures creates no duplicate of an already imported row.
- [ ] Tests: widget test of `import_summary_screen.dart` over a mixed-outcome result, an all-successful result and the
      four states, asserting retry re-runs only failures.
- [ ] The empty Projects list offers import again, reading `Copy.projectsImport`, and the control it offers works.
- [ ] Tests: widget test of `project_list_screen.dart` asserting the import control is shown and reaches this flow.

## Out of scope

- Reading a bundle and merging it. The entry screen routes a bundle and refuses a bad one; the reader, the preview and
  the merge belong to 114 · Bundles and merge.
- Importing a reference dataset or creating a template from a workbook. This phase routes both; the dataset importers
  belong to 105 · Reference data and the template flow to [102](../09-templates/102-xlsx-mapping-screen.md).
- Duplicate detection, the verification prefill a register import feeds, and the variance it later produces. This
  phase supplies the rows and the import-side choice; 110 · Data quality owns all three.
- Record export in any format. This phase writes only the corrective list of skipped and failed rows, and 113 · Export
  produces everything else.
