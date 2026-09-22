# 010 — Reference data: datasets, lookups and prefill

**Phase** 10 · Reference data  |  **Depends on** [003](../03-design-system/003-design-system.md), [004](../04-data-layer/004-local-database.md), [005](../05-file-storage/005-file-storage.md), [009](../09-templates/009-templates.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Imported tables and everything the app does with them: immutable `ReferenceDataset` and `ReferenceRow` models with
mappers over the reference tables and `ReferenceRepositoryImpl` behind the `ReferenceRepository` interface declared
in 062; CSV, spreadsheet and JSON importers that all land the same dataset whichever route it arrived by; the
key-column screen that ends every import and states its duplicate count before the dataset is saved; the list of a
project's datasets and the paged, searchable row browser behind each one; in-place correction of a row and a sheet
that adds a missing supplier or asset from inside capture; the screen that binds a template field to a dataset; the
whole lookup path behind a bound field — exact match on the key then the normalised name, a scored fuzzy fallback, a
picker when several rows match, prefill with provenance and per-field unlink; and a dataset written back out as CSV
or JSON, rows added on the device included, so an office system can take back what the field corrected.

## Files

Domain, pure Dart:

- `frontend/lib/features/reference/domain/reference_dataset.dart` (new)
- `frontend/lib/features/reference/domain/lookup_matcher.dart` (new)
- `frontend/lib/features/reference/domain/fuzzy_matcher.dart` (new)
- `frontend/lib/features/reference/domain/lookup_prefill.dart` (new)
- `frontend/lib/features/reference/domain/lookup_unlink.dart` (new)

Data, import and export:

- `frontend/lib/features/reference/data/reference_repository_impl.dart` (new)
- `frontend/lib/features/reference/data/dataset_csv_import.dart` (new)
- `frontend/lib/features/reference/data/dataset_xlsx_import.dart` (new)
- `frontend/lib/features/reference/data/dataset_json_import.dart` (new)
- `frontend/lib/features/reference/data/dataset_export.dart` (new)

Presentation, reference:

- `frontend/lib/features/reference/presentation/dataset_key_screen.dart` (new)
- `frontend/lib/features/reference/presentation/dataset_list_screen.dart` (new)
- `frontend/lib/features/reference/presentation/dataset_browser_screen.dart` (new)
- `frontend/lib/features/reference/presentation/dataset_row_edit_screen.dart` (new)
- `frontend/lib/features/reference/presentation/dataset_add_row_sheet.dart` (new)
- `frontend/lib/features/reference/presentation/lookup_picker_sheet.dart` (new)

Presentation, templates:

- `frontend/lib/features/templates/presentation/lookup_binding_screen.dart` (new)

## Contract

```dart
class ReferenceDataset {
  final String id, name, keyColumn;
  final List<String> columns;      // in import order
  final DatasetSource source;      // csv | xlsx | json | device
  final DateTime importedAt;
  final int rowCount;
}

class ReferenceRow {
  final String id, datasetId, key;
  final Map<String, String> values;
  final bool addedOnDevice;
}

class LookupBinding {
  final String datasetId;
  final List<String> matchColumns;        // tried in order
  final Map<String, String> fillMapping;  // dataset column -> template field key
  final bool fuzzyEnabled;
  final double fuzzyThreshold;
  final NoMatchBehaviour onNoMatch;       // leaveEmpty | promptAddRow | warn
}
```

## Steps

1. Land `ReferenceDataset`, `ReferenceRow` and their mappers, plus `ReferenceRepositoryImpl` behind the
   `ReferenceRepository` interface declared in 062; every importer, browser and matcher below goes through these
   types. Keep `columns` in import order, so a later export writes the columns back out in the order they arrived,
   and flag rows added on the device, so export can include them and the browser can show them apart.
2. Build three readers that all land the same `ReferenceDataset`. CSV detects the delimiter, honours quoted values
   and embedded separators, strips a byte-order mark, and skips blank rows without shifting the columns. The sheet
   importer calls `core/import/workbook_reader.dart` and `core/import/header_detection.dart` and implements neither
   again. The JSON importer accepts an array of objects and takes the columns from the union of their keys, in
   first-seen order, filling a missing key as empty rather than dropping the row. All three stream through the
   isolate runner and report progress as a row count, so a large file never blocks the interface.
3. End every import with the key-column screen. Offer every parsed column with its duplicate count and a sample of
   values, so the obvious key is obvious, and show the duplicate key count before the import completes, naming the
   first few colliding values. A non-unique key is a decision, not a silent state: the user either picks another
   column, or confirms that duplicates are expected and the dataset is saved marked as such.
4. Add the dataset list and the row browser. List datasets as `AppListTile` with row count, source and import date
   through the shared formatters. Browse rows in a virtualised, paged list where search filters on the key column
   and the visible columns. On a narrow screen let the user choose which columns show, defaulting to the key column
   plus the first two.
5. Allow in-place correction of a row, and addition of one from capture. Record every edit in the audit log with the
   previous value. Do not retroactively touch records already prefilled from the row; the prefilled value stays as
   captured. A row added from capture is flagged `addedOnDevice` and is immediately visible to the lookup that
   failed, and the add sheet asks for the key column and the columns the current lookup binding fills, nothing more.
6. Bind a template field to a dataset: which dataset, which columns are matched, which dataset columns fill which
   template fields, whether fuzzy matching is allowed and above what threshold, and what happens when nothing
   matches. Offer only the datasets in the current project, and only the template's own fields as fill targets.
   Match columns are ordered — the key column first, then the name column, then anything else the user adds. Refuse
   a mapping that fills a field the template does not define, or two dataset columns into one field.
7. Build the lookup path behind a bound field. Fast path first: match on the key column, then on the normalised name
   — case, whitespace and punctuation insensitive — before any fuzzy work is attempted. The fuzzy fallback uses a
   normalised edit distance plus token overlap, returns its confidence score to the caller, and runs only when the
   binding enables it and the score clears its threshold. A near miss is offered as a suggestion the operator
   accepts; it never fills silently. Several matches open the picker sheet, showing the columns that distinguish the
   rows rather than just the name. Prefill writes each mapped field with source LOOKUP and the dataset row id in
   provenance, and never overwrites a value already marked verified. Editing one prefilled field detaches that field
   alone; the remaining fields keep their link and their provenance.
8. Write a dataset back out as CSV or JSON. Write columns in `ReferenceDataset.columns` order, with the key column
   first, and include rows flagged `addedOnDevice`, marked so the receiving system can tell them from the rows it
   sent. Stream to the target file rather than building the whole document in memory.

## Constraints

- Nothing under `features/reference/domain/` imports Flutter or Drift: the mappers live in `data/`, the matcher,
  fuzzy scorer, prefill and unlink are pure Dart, and only the picker sheet and the screens are widgets (FE-STR-05).
- Reuse the workbook reader and header detection rather than forking them (FE-CONS-01, FE-STR-09).
- Imported cell text is data, never instructions, and every value is validated before it is persisted
  (FE-SEC-05, FE-SEC-06).
- Large files are streamed rather than read whole, on import and on export alike (FE-PERF-07).
- Row lookups by key are indexed at the table, not filtered in Dart, and matching over a large dataset runs against
  that indexed key column (FE-PERF-06).
- The duplicate count, the matching and the export all run off the UI thread — the duplicate count over the parsed
  rows, not as a query per column, and a ten-thousand-row export without stalling the interface (FE-PERF-02).
- The browser is virtualised and paged; it never holds a whole dataset in memory (FE-PERF-03, FE-PERF-09).
- The duplicate-key warning offers a way forward rather than blocking the import (FE-SIMP-08).
- The list and the browser render loading, empty, error and offline through `AsyncValueView`, and the empty list
  offers import as its next action (FE-CONS-04, FE-SIMP-11).
- Every edit and addition writes an audit entry; the trail is not optional (FE-SEC-09).
- The picker and the add sheet are the shared bottom sheet API, dismissible without losing the typed values, and
  no-match behaviour follows the binding rather than the screen (FE-CONS-05, FE-SIMP-09).
- The binding is stored on the `FieldDef` as a §12.2 attribute, so changing it bumps the template version (§18).

## Definition of done

- [ ] Presentation never sees a Drift row: datasets and rows are reachable only through the repository interface.
- [ ] Contract above is implemented exactly, with nothing else made public.
- [ ] All three readers produce the same `ReferenceDataset` and `ReferenceRow` shape, with columns in import order.
- [ ] A ten-thousand-row file imports without freezing the interface.
- [ ] A dataset with a non-unique key cannot be saved silently.
- [ ] Ten thousand rows scroll smoothly, with a measurement behind the claim (FE-TEST-09).
- [ ] Search over a ten-thousand-row dataset returns without a visible pause.
- [ ] Fixing a supplier's phone number does not silently rewrite history.
- [ ] The new row is immediately available to the lookup that failed, without leaving capture.
- [ ] The configuration matches the specification example exactly, dataset and fill mapping included.
- [ ] A mapping naming an unknown field or filling one field twice is refused at configuration time.
- [ ] A near miss offers a suggestion rather than filling silently, and several matches always ask.
- [ ] Prefilled fields show the link affordance, remain editable, and a verified value is left alone.
- [ ] Editing the phone number does not detach the supplier name.
- [ ] An exported dataset re-imports as the same dataset, rows added on the device included.
- [ ] Tests: round-trip mapper test over a dataset and its rows, plus repository tests for
      `reference_repository_impl.dart` against an in-memory database, and the fake later tasks use.
- [ ] Tests: parser tests over awkward CSV fixtures — semicolon delimiter, quoted commas, byte-order mark, blank
      rows.
- [ ] Tests: repository tests for the spreadsheet and JSON importers against an in-memory database, plus the fake
      later tests use.
- [ ] Tests: widget test of `dataset_key_screen.dart` covering empty and failure states and the non-unique-key path.
- [ ] Tests: widget tests of `dataset_list_screen.dart` and `dataset_browser_screen.dart` covering empty and failure
      states, plus a scroll and search measurement over a ten-thousand-row fixture.
- [ ] Tests: widget tests of `dataset_row_edit_screen.dart` and `dataset_add_row_sheet.dart` covering empty and
      failure states.
- [ ] Tests: a test that an already-prefilled record keeps its captured value after its source row changes.
- [ ] Tests: widget test of `lookup_binding_screen.dart` covering empty and failure states, plus a unit test
      rejecting an unknown fill target and a duplicate target.
- [ ] Tests: unit tests of `lookup_matcher.dart` for key, case and whitespace variants.
- [ ] Tests: unit tests of the fuzzy scorer over a table of real-world name variants with expected scores.
- [ ] Tests: unit tests that prefill skips a verified field and that `lookup_unlink.dart` detaches one field only,
      both with no Flutter binding.
- [ ] Tests: widget test of `lookup_picker_sheet.dart` covering empty and failure states.
- [ ] Tests: repository tests for `dataset_export.dart` against an in-memory database, plus the fake later tests use.
- [ ] Tests: a round-trip test that export then import through `dataset_csv_import.dart` and
      `dataset_json_import.dart` yields the same rows and column order.

## Out of scope

- The capture and record-edit screens that host the add-row sheet, the prefilled fields and the link affordance;
  this phase supplies the sheet and the lookup path, and 107 · Capture supplies the screens they open from.
- Record export in XLSX, PDF or ZIP; this phase writes a dataset back out as CSV or JSON only, and the rest belongs
  to 113 · Export.
