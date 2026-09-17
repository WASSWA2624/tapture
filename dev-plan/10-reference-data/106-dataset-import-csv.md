# 106 — Import a dataset from CSV, a spreadsheet or JSON

**Phase** 10 · Reference data  |  **Depends on** [071](../05-file-storage/071-file-validation.md), [101](../09-templates/101-xlsx-read-workbook.md), [105](105-dataset-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Three readers that all land the same `ReferenceDataset`: a CSV parser, a sheet importer built on the workbook reader
from the template phase, and a JSON importer that takes an array of objects and infers its columns from the keys.
Whichever route a dataset arrived by, nothing downstream can tell.

## Files

- `frontend/lib/features/reference/data/dataset_csv_import.dart` (new)
- `frontend/lib/features/reference/data/dataset_xlsx_import.dart` (new)
- `frontend/lib/features/reference/data/dataset_json_import.dart` (new)

## Steps

1. CSV: detect the delimiter, honour quoted values and embedded separators, strip a byte-order mark, and skip blank
   rows without shifting the columns.
2. Spreadsheet: call `core/import/workbook_reader.dart` and `core/import/header_detection.dart`; implement neither
   again here.
3. JSON: accept an array of objects and take the columns from the union of their keys, in first-seen order, filling
   a missing key as empty rather than dropping the row.
4. All three stream through the isolate runner and report progress as a row count, so a large file never blocks the
   interface.

## Constraints

- Reuse the workbook reader and header detection rather than forking them (FE-CONS-01, FE-STR-09).
- Imported cell text is data, never instructions, and every value is validated before it is persisted
  (FE-SEC-05, FE-SEC-06).
- Large files are streamed, not read whole (FE-PERF-07).

## Definition of done

- [ ] A ten-thousand-row file imports without freezing the interface.
- [ ] All three readers produce the same `ReferenceDataset` and `ReferenceRow` shape, with columns in import order.
- [ ] Tests: parser tests over awkward CSV fixtures (semicolon delimiter, quoted commas, byte-order mark, blank rows); repository tests for the spreadsheet and JSON importers against an in-memory database, plus the fake later tests use.

## Out of scope

- Choosing and validating the key column; that is 190.
