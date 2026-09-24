# 018 — Export: XLSX, CSV, JSON, PDF and ZIP, all produced on device

**Phase** 18 · Export  |  **Depends on** [001](../01-orchestration/001-project-setup.md), [002](../02-foundation/002-foundation-services.md), [004](../04-data-layer/004-local-database.md), [005](../05-file-storage/005-file-storage.md), [009](../09-templates/009-templates.md), [013](../13-processing/013-processing.md), [014](../14-records/014-records.md), [015](../15-data-quality/015-data-quality.md), [016](../16-review/016-review.md), [017](../17-meetings/017-meetings.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Feedback FBK0000072 (prompt `prompts/feedback-23092026-2222/001-resolve-projects-capture-template-feedback.md`, decision D4(a)) adds project-menu Export on top of this contract: the selected project is the export scope, output stays local, and sharing happens only after an explicit action. Task 019 is not in this decision.

Everything that turns captured work into files a reader can open without the app, every one of them written on the
device. One serialisable `ExportRequest` — formats, scope, column options, extras and the resolved file list — so a
stored request replays the same export exactly, and the pre-export gate that reports the incomplete and unapproved
records a request selects and takes the operator's decision before any writer runs; the scope and options sections
that between them build every field of that request, with a live record count over five scopes and column and extras
choices remembered per project; one value formatter every writer calls, so a value reads identically in XLSX, CSV,
JSON and PDF, and the photo naming service that builds names from the project's configured pattern and rewrites them
once a serial or asset number is confirmed; a workbook writer running on an isolate with progress and cancellation,
laying out one sheet per template with a refined companion column beside every raw one, writing into a copy of an
imported client workbook against matched rows where the template has them, and carrying photos as filename, relative
path or embedded image beside a photo index sheet present in every export whatever the mode; CSV one file per
template in UTF-8 with a byte-order mark and a configurable delimiter, full-fidelity JSON carrying raw, refined and
final values with their provenance, and the data dictionary that lets an analyst read either without the app; one PDF
foundation — cover, running header, numbered footer and the photo block every report shares — and the five reports
of A52 built on it: record, inspection, project summary, variance and meeting minutes; a ZIP package holding the chosen
outputs, the photos, the attached documents and a manifest mapping every exported record to its output row and photo
paths, so the package explains itself years later; and the one screen that assembles a whole export with per-stage
progress and a cancellation that leaves nothing behind, over a history where every export is recorded, lands in its
own versioned dated folder that nothing later overwrites, and can be shared again without being regenerated.

## Files

Request, validation and versioning — pure Dart:

- `frontend/lib/features/exports/domain/export_request.dart` (new)
- `frontend/lib/features/exports/domain/export_validation.dart` (new)
- `frontend/lib/features/exports/domain/export_versioning.dart` (new)

Shared formatting and naming:

- `frontend/lib/core/export/value_formatter.dart` (new)
- `frontend/lib/core/export/photo_naming.dart` (new)
- `frontend/lib/core/export/photo_rename.dart` (new)

The XLSX family:

- `frontend/lib/core/export/xlsx_writer.dart` (new)
- `frontend/lib/core/export/xlsx_refined_columns.dart` (new)
- `frontend/lib/core/export/xlsx_multi_sheet.dart` (new)
- `frontend/lib/core/export/xlsx_template_copy.dart` (new)
- `frontend/lib/core/export/xlsx_row_targeting.dart` (new)
- `frontend/lib/core/export/xlsx_photo_refs.dart` (new)
- `frontend/lib/core/export/photo_index_sheet.dart` (new)

CSV, JSON and the data dictionary:

- `frontend/lib/core/export/csv_writer.dart` (new)
- `frontend/lib/core/export/json_writer.dart` (new)
- `frontend/lib/core/export/data_dictionary.dart` (new)

The PDF family:

- `frontend/lib/core/export/pdf/pdf_engine.dart` (new)
- `frontend/lib/core/export/pdf/record_report.dart` (new)
- `frontend/lib/core/export/pdf/inspection_report.dart` (new)
- `frontend/lib/core/export/pdf/summary_report.dart` (new)
- `frontend/lib/core/export/pdf/variance_report.dart` (new)
- `frontend/lib/core/export/pdf/minutes_report.dart` (new)

The archive:

- `frontend/lib/core/export/zip_package.dart` (new)
- `frontend/lib/core/export/export_manifest.dart` (new)

Screens and sections:

- `frontend/lib/features/exports/presentation/export_scope_section.dart` (new)
- `frontend/lib/features/exports/presentation/export_options_section.dart` (new)
- `frontend/lib/features/exports/presentation/export_screen.dart` (new)
- `frontend/lib/features/exports/presentation/export_progress.dart` (new)
- `frontend/lib/features/exports/presentation/export_history_screen.dart` (new)
- `frontend/lib/features/exports/presentation/export_share_action.dart` (new)

## Contract

```dart
enum ExportFormat { xlsx, csv, json, pdf, zip }

class ExportRequest {
  const ExportRequest({
    required this.projectId,
    required this.formats,
    required this.scope,
    required this.columns,
    required this.extras,
    this.markedIncomplete = false,
  });
  factory ExportRequest.fromJson(Map<String, Object?> json);
  Map<String, Object?> toJson();
}

enum ExportGateChoice { fixNow, excludeThem, exportAnyway }

class ExportValidationReport {
  const ExportValidationReport(this.incomplete, this.unapproved);
  final List<String> incomplete;
  final List<String> unapproved;
  bool get isClean;
}

class ExportValueFormatter {
  const ExportValueFormatter(this.registry);
  /// Rendered form of [value] for [target]; `null` becomes the empty string.
  String format(Object? value, FieldType type, ExportFormat target);
  /// Typed form for writers that carry native cell types, e.g. XLSX dates and numbers.
  Object? typed(Object? value, FieldType type);
}

class PhotoNaming {
  const PhotoNaming(this.pattern);
  /// Sanitised, collision-free name for [photo]; unresolved tokens fall back in a fixed order.
  String nameFor(PhotoNamingTokens tokens, {required Set<String> taken});
}

class PhotoRenamer {
  /// Renames every provisional file of [recordId] and updates its stored path in one transaction.
  Future<int> renameForIdentity(String recordId);
}

class XlsxWriter {
  /// Writes [records] to [target]; emits 0..1 progress. Cancels when [token] is cancelled.
  Stream<double> write({
    required File target,
    required ExportRequest request,
    required CancellationToken token,
  });
}

class SheetPlan {
  const SheetPlan(this.templateId, this.sheetName, this.columns);
}

class PdfEngine {
  const PdfEngine(this.tokens);
  PdfDocumentBuilder document({required PdfCover cover, required PdfRunningHeader header});
  /// Photo grid used by every report; [columns] is 1 for full-size, 2..4 for thumbnails.
  PdfBlock photoBlock(List<ExportPhoto> photos, {required int columns, bool captions = true});
  /// Renders on the isolate runner of 024; emits 0..1 progress.
  Stream<double> render(PdfDocumentBuilder builder, File target, CancellationToken token);
}

class ExportManifest {
  const ExportManifest({
    required this.exportId,
    required this.createdAt,
    required this.request,
    required this.entries,
  });
  Map<String, Object?> toJson();
}

class ManifestEntry {
  const ManifestEntry(this.recordId, this.recordNumber, this.sheet, this.row, this.photoPaths);
}

class ExportVersioning {
  /// Allocates the next `vN` directory for [projectId] under today's date; never reuses one.
  Future<Directory> allocate(String projectId, DateTime now);
}
```

## Steps

### The request and its options

1. Build `export_request.dart` and `export_validation.dart` first; every writer in this phase takes a request and
   nothing else. Keep every field of the request in `toJson`, including the resolved file list, so history can re-run
   it unchanged. Read validation results from the engine of [015](../15-data-quality/015-data-quality.md) — its
   export-set check in particular — rather than re-implementing field checks here. The gate offers `fixNow`,
   `excludeThem` and `exportAnyway`; on `exportAnyway`, set `markedIncomplete` so the writers stamp the fact into the
   output itself.
2. Build the scope and options sections. Both are plain sections with no screen of their own. Offer five scopes:
   approved only, all records, current context subtree, date range, and the current filter of
   [014](../14-records/014-records.md). Recompute the record count whenever the scope changes, off the build method.
   Offer raw columns, refined columns, confidence, evidence and the extra sheets, defaulting refined columns on for
   every field that has a refined value. Persist the options per project so the next export opens with the last
   choice.

### Shared formatting and naming

3. Build `value_formatter.dart`, the one formatter every writer calls. Handle dates, numbers with units, choices with
   their codes, booleans, multi-values and nulls, giving multi-values one separator across all formats. Render
   identifiers as text always, preserving leading zeros and never coercing them to numbers. Take normalised dates and
   units from [013](../13-processing/013-processing.md); do not parse date strings here.
4. Build `photo_naming.dart` and `photo_rename.dart`. Support the specification's token set, including each context
   level, record number, photo type and sequence; sanitise through the segment sanitiser of
   [005](../05-file-storage/005-file-storage.md) and de-duplicate against names already taken. Rename on the
   identity hash of 110 confirming a serial or asset number, moving the file and updating the stored path in one
   transaction, so no row ever points at a missing file. Keep the original filename in photo metadata and write a
   history entry for the rename.

### The XLSX family

5. Build `xlsx_writer.dart`, `xlsx_refined_columns.dart` and `xlsx_multi_sheet.dart`. Build a `SheetPlan` per template
   first: unique, valid sheet names derived from template names, then the column order from the field keys. Insert
   each refined companion column next to its raw column with a clear header suffix, without shifting any mapping
   already recorded for that template; which side is authoritative comes from the raw-or-refined choice of
   [016](../16-review/016-review.md). Append rows after the last used row of the sheet, writing native cell types
   through `ExportValueFormatter.typed`. Run the whole write inside the isolate runner of
   [002](../02-foundation/002-foundation-services.md), streaming progress per record batch.
6. Build `xlsx_template_copy.dart` and `xlsx_row_targeting.dart`, so an export against an imported workbook leaves the
   stored file untouched. Copy the stored template to the export folder, then open only the copy. Resolve each record
   to a row through the row matcher of 108 over the column mapping recorded in
   [009](../09-templates/009-templates.md); append only when the template has no predefined rows. Leave a
   row that never matched visibly empty or marked not found, and count those rows for the export summary. Report in
   that summary every workbook feature the library could not preserve.
7. Build `xlsx_photo_refs.dart` and `photo_index_sheet.dart`. Implement filename and relative path first; both come
   from `PhotoNaming`, never from the stored file path. Embedding adjusts row height and reports the resulting file
   size growth; it changes no other column. Write the index sheet with one row per photo — record, photo type, caption
   and path — and include it in every export, whatever the reference mode, so photos stay traceable even in filename
   mode.

### CSV, JSON and the data dictionary

8. Build `csv_writer.dart`, `json_writer.dart` and `data_dictionary.dart`. CSV writes one file per template in UTF-8
   with a byte-order mark and a configurable delimiter, quoting fields containing the delimiter, quotes or newlines,
   escaping embedded newlines, and zipping the set when more than one template produces a file. JSON is the
   full-fidelity output: stream records to the sink one at a time, carrying values raw, refined and final with the
   provenance and evidence references of 108, confidence, context path and the template version each record was
   captured under. The dictionary emits key, label, type, unit, options with their codes, required flag and
   description for every field of every exported template, taken from the registry of
   [009](../09-templates/009-templates.md).

### The PDF family

9. Build `pdf/pdf_engine.dart`, the one foundation every report stands on: cover page, running header, footer with
   page numbers, and the photo block used wherever photos appear. Take every size, weight and spacing value from the
   type scale and spacing tokens, so reports look like the app. Number pages as `n of m` in the footer and repeat the
   project and report name in the header of every page. Expose cover slots a report fills with its own totals, rather
   than each report drawing its own cover. Render through the isolate runner of 024, with progress and cancellation.
10. Build `pdf/record_report.dart` and `pdf/inspection_report.dart`, the two record-level reports of A52. The record
    report renders each record as a page or block with its fields, photos, captions, context path and operator,
    offering thumbnail and full-size photo layouts, both through the engine's photo block. The inspection report
    renders a checklist template — `inspection_check` and anything derived from it — ordered by the predefined rows
    of [009](../09-templates/009-templates.md) (A15), so it reads in the order the inspector worked
    rather than in capture order. Render each checklist row as its result, observation, risk and recommendation,
    with the photos evidencing it beneath; a row never found prints as **Not found** — a finding, not a gap (A15).
    Carry the compliance total and the count of not-found rows onto the cover, so the deliverable states its own
    completeness. Print the raw observation beside the refined one wherever the field carries both and the project
    has that option on (A32).
11. Build `pdf/summary_report.dart` and `pdf/variance_report.dart`, the two project-level reports. The summary counts
    records by context, template, condition and status with simple charts; aggregate the counts once per report and
    pass the totals to the engine's cover slots. Draw charts from the same token palette as the app; a chart never
    carries information its table does not. The variance report sets as-recorded against as-found: read the variance
    rows and missing items of 110 and present matched, missing and not-in-register as three labelled sections, each
    item carrying its register key.
12. Build `pdf/minutes_report.dart`, the fifth report of A52: attendance list, agenda items with their decisions and
    actions, and a photo appendix. Take the refined text and the raw transcript from
    [017](../17-meetings/017-meetings.md) and set them side by side, each labelled as which it is; never present
    refined text as if it were recorded speech. Put photos in an appendix through the engine's photo block, referenced
    from the item that mentions them.

### The ZIP package

13. Build `zip_package.dart` and `export_manifest.dart`. Lay the archive out exactly as the specification shows, and
    add each entry as a stream rather than reading files into memory. It holds the chosen outputs, the photos and the
    attached documents. Write the manifest last, once every output path and row index is known, and match the
    specification's manifest example field for field, including the request that produced it.

### The screen and history

14. Build `export_screen.dart` and `export_progress.dart`. Assemble the scope and options sections of step 2
    unchanged rather than restating their controls, and open with the project's remembered options already applied, so
    a default export is one tap. Show progress per stage — records, photos, reports, archive — using the shared
    progress steps control. On cancellation, stop the isolate and delete every partial file, including the
    half-written archive.
15. Build `export_history_screen.dart`, `export_versioning.dart` and `export_share_action.dart`. Store per export, in
    the table of [004](../04-data-layer/004-local-database.md): timestamp, operator, formats, the resolved request and
    its filters, record count, output path and the file hash from 024; stamp every included record with
    `exportedAt`. Allocate `v1`, `v2` and so on per project inside dated directories under the project's export folder
    of 066, so a repeated export never overwrites an earlier one. Re-share from history by handing the recorded path
    to the system share sheet; regenerate nothing. Show a missing file plainly when the recorded path has since been
    deleted, and offer to re-run the request instead.

## Constraints

- `export_request.dart`, `export_validation.dart`, `export_versioning.dart` and everything under `core/export/` stay
  pure Dart: no Drift, Flutter or HTTP import, so the PDF and CSV writers can share them from an isolate (FE-STR-05).
- A stored request replays its export exactly. Every field, including the resolved file list, survives `toJson`, and
  an export marked incomplete carries that mark into the output rather than only into the app.
- Every completed export is recorded — row, hash, path, the request and its filters, and the record count — and
  every record it carried is stamped `exportedAt`; `filters` records the query, never the exported values (FE-SEC-09).
- Raw evidence is never destroyed. Renaming moves a file and records the old name, never rewrites pixels; the stored
  client template is read-only input that nothing here opens for writing; a refined passage carries its label in the
  document itself wherever it appears (FE-SEC-08, FE-SEC-09).
- `ExportValueFormatter` is the single formatter for exported values (FE-CONS-09); a writer that formats a value
  itself is a defect, and names are derived only from the configured pattern, so no writer invents its own naming.
- The gate presents one decision through the shared dialog service; it never builds its own dialog (FE-CONS-05).
- The scope and options sections render the four states of FE-CONS-04, and the count never blocks on a query in
  `build` (FE-PERF-02). Extras and column detail sit in a collapsed advanced group (FE-SIMP-06); no new control is
  invented for either section (FE-CONS-01).
- The UI thread renders no cell and no page and holds no workbook (FE-PERF-02); every writer streams to file and never
  holds the whole document in memory (FE-PERF-07), and archive entries stream in and out.
- The spreadsheet, PDF, archive and share packages are the ones allowed by
  [001](../01-orchestration/001-project-setup.md); no second XLSX, PDF or archive dependency is added, and the
  share plug-in is reached through a platform wrapper (FE-STR-11).
- Validate the chosen spreadsheet library against a real client workbook before committing to it; formatting loss is a
  correctness failure here, not a cosmetic one.
- Embedded images are downscaled from thumbnails, not full-resolution originals, so a large project still exports
  (FE-PERF-04).
- PDF styles come from tokens only; no report declares a font size or colour of its own (FE-THEME-01, FE-THEME-11),
  and no report starts a second PDF foundation beside the engine (FE-CONS-02).
- Charts are readable without colour: label every series (FE-THEME-05). Aggregation happens off the UI thread with the
  rest of the render (FE-PERF-02).
- Checklist progress and the not-found set are read from the checklist of 103 and the missing-item computation of
  110, never recomputed here (FE-STATE-06).
- Export is the single primary action of its screen (FE-SIMP-01); progress arrives as isolate messages and the screen
  performs no export work itself (FE-PERF-02).

## Definition of done

### The request and its options

- [ ] An `ExportRequest` survives a JSON round trip unchanged, field for field, so a stored request replays the same
      export.
- [ ] An export marked incomplete says so inside the produced file, not only in the app.
- [ ] Each of `fixNow`, `excludeThem` and `exportAnyway` leads to the outcome it names.
- [ ] Tests: unit tests of `export_request.dart` (round trip) and `export_validation.dart` (all three gate paths and
      the clean path), with no Flutter binding.
- [ ] The chosen scope shows a live record count before the export starts, and the count follows filter changes.
- [ ] Refined columns arrive on by default for refined fields; the choice is remembered per project.
- [ ] Tests: widget tests of `export_scope_section.dart` and `export_options_section.dart` covering each of the five
      scopes, the empty and failure states, and that saved options are restored.

### Shared formatting and naming

- [ ] XLSX, CSV, JSON and PDF show the same value in the same way for every registry type.
- [ ] An asset number such as `00734` exports as `00734` in all four formats.
- [ ] Tests: table-driven unit tests of `value_formatter.dart` over every field type crossed with every target format,
      including null and multi-value cases.
- [ ] Names match the specification examples exactly, and two photos in one record never collide.
- [ ] A photo taken before identification ends up correctly named, with its original name still recoverable.
- [ ] References from records, the manifest and the photo index still resolve after a rename.
- [ ] Tests: unit tests of `photo_naming.dart` over the full token set and collision handling, and of
      `photo_rename.dart` asserting path rows and references stay consistent after renaming, with no Flutter binding.

### The XLSX family

- [ ] A five-thousand-record export finishes in under thirty seconds with visible progress and no dropped frames.
- [ ] A multi-template project produces one validly named sheet per template, with no name collisions.
- [ ] Raw and refined values appear side by side and neither is lost.
- [ ] Tests: unit tests of `xlsx_writer.dart` reopening the output through a spreadsheet reader and asserting cell
      types, the headers of both column pairs and the sheet names.
- [ ] Tests: a measured test backing the thirty-second claim (FE-TEST-09).
- [ ] The stored template file is byte-identical after every export.
- [ ] Client formatting, formulas and sheet order survive in the copy, and anything lost is named in the summary.
- [ ] A predefined row that no record matched stays visibly empty or marked not found, and is counted.
- [ ] Tests: unit tests of `xlsx_template_copy.dart` hashing the template before and after a write, and of
      `xlsx_row_targeting.dart` over matched, unmatched and duplicate-match rows.
- [ ] Switching reference mode changes only the photo column; every other column is byte-identical.
- [ ] Every photo of every exported record appears exactly once on the index sheet, resolvable back to its file.
- [ ] Tests: unit tests of `xlsx_photo_refs.dart` over all three modes and of `photo_index_sheet.dart` asserting one
      row per photo, including records with none.

### CSV, JSON and the data dictionary

- [ ] A CSV file round-trips through a standard reader with delimiters, quotes and newlines intact.
- [ ] A ten-thousand-record project exports to JSON without memory exceeding its baseline budget.
- [ ] The dictionary describes every field present in the CSV and JSON output, so an analyst needs no other source.
- [ ] Tests: unit tests of `csv_writer.dart` (round trip through a CSV reader), `json_writer.dart` (schema validation
      plus a measured memory assertion) and `data_dictionary.dart` (every exported field described), with no Flutter
      binding.

### The PDF family

- [ ] Every report can be built from cover, header, footer and photo block without adding layout of its own.
- [ ] A cancelled render leaves no partial file.
- [ ] Tests: golden test of a rendered cover and body page through `pdf_engine.dart`, plus a unit test that
      cancellation deletes the target file.
- [ ] A record's fields, photos with captions, context path and operator all appear, in both photo layouts.
- [ ] An inspection row that was never captured appears as **Not found** rather than being omitted, and is counted on
      the cover.
- [ ] Tests: golden tests of a rendered record page and inspection page, plus unit tests asserting inspection row
      order follows the predefined rows and that not-found rows are present.
- [ ] Summary counts by context, template, condition and status agree with the same counts shown in the app.
- [ ] The variance report names every missing and every not-in-register item, with its register key.
- [ ] Tests: golden test of one page of each of the summary and variance reports, plus unit tests of
      `summary_report.dart` aggregation and of `variance_report.dart` section membership against a seeded fixture.
- [ ] Attendance, agenda items, decisions, actions and the photo appendix all appear for a seeded meeting.
- [ ] Both raw and refined minutes can be included, and a reader can always tell which is which.
- [ ] Tests: golden test of a rendered minutes page, plus a unit test asserting raw and refined passages are labelled
      distinctly.
- [ ] All five reports of A52 exist and share the one PDF foundation; none declares a font size, colour or layout of
      its own.

### The ZIP package

- [ ] A four-hundred-megabyte package builds without memory exceeding its baseline budget.
- [ ] Extracting the archive reproduces the documented folder layout exactly.
- [ ] Every exported record appears once in the manifest with its sheet, row and photo paths.
- [ ] The manifest matches the specification's example field for field, including the request that produced it.
- [ ] Tests: unit tests of `zip_package.dart` asserting archive layout after extraction with a measured memory
      assertion, and a schema test of the manifest produced by `export_manifest.dart`.

### The screen and history

- [ ] A default export needs one tap after opening the screen.
- [ ] Each stage reports progress, and the interface stays responsive throughout.
- [ ] A cancelled export leaves no partial output file or archive on disk.
- [ ] Tests: widget tests of `export_screen.dart` and `export_progress.dart` covering the four states, the one-tap
      default and a cancellation asserting no file remains.
- [ ] A user can explain, months later, exactly what a given file contained and who produced it.
- [ ] Every completed export writes its history row, and every record it included carries its `exportedAt` stamp.
- [ ] A new export never destroys a previous one, and folder names are stable and dated.
- [ ] Sharing from history reaches the system share sheet without rebuilding the file, and a recorded path since
      deleted shows plainly with an offer to re-run the request.
- [ ] Tests: widget tests of `export_history_screen.dart` and `export_share_action.dart` covering the four states and
      a missing file, plus unit tests of `export_versioning.dart` over repeated allocations on the same day, with no
      Flutter binding.

## Out of scope

- Sending an export anywhere. This phase writes files into the project's export folder and hands a recorded path to
  the system share sheet; destinations, credentials and uploads belong to 116 · Cloud upload.
- The encrypted collaboration bundle. The archive here is a deliverable for a reader outside the app, not a transfer
  format the app reads back; that is 114 · Bundles and merge.
- The capture-to-export integration run over the whole slice, which belongs to 120 · Testing and release.
