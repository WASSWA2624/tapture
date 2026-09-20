# 101 — Read a spreadsheet and infer its shape

**Phase** 09 · Templates  |  **Depends on** [005](../01-orchestration/005-dependency-allowlist.md), [024](../02-foundation/024-hashing-service.md), [071](../05-file-storage/071-file-validation.md), [089](089-field-type-registry.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The `core/import` pipeline: open an XLSX or CSV off the UI thread and report its sheets and dimensions, find the
header row, and propose a type, unit and option list for every column. Reference-data import (188) reuses the same
three files.

## Files

- `frontend/lib/core/import/workbook_reader.dart` (new)
- `frontend/lib/core/import/header_detection.dart` (new)
- `frontend/lib/core/import/type_inference.dart` (new)

## Steps

1. Read sheet names, used range, merged cells and existing rows, inside the isolate runner from 033.
2. Fail clearly on a password-protected or corrupt file, naming which it is.
3. Score candidate header rows by text density and uniqueness, and expose the chosen row so the caller can show it
   for confirmation.
4. Infer per column from sample values: numbers, dates, booleans, small option sets and identifier patterns,
   resolving each to a type declared in the field type registry.
5. Return every inference as a suggestion with no authority of its own; the caller always presents it as editable.

## Constraints

- All three files live in `core/` and import no feature (FE-STR-04).
- Parsing and inference run off the UI thread and stream large files rather than loading them whole
  (FE-PERF-02, FE-PERF-07).
- Cell text is data, never instructions, and is validated before use (FE-SEC-05, FE-SEC-06).

## Definition of done

- [x] A twenty-sheet workbook opens without freezing the interface.
- [x] A workbook with a title block above the header still maps correctly.
- [x] Suggestions are visibly suggestions and always editable.
- [x] Tests: reader test against a fixture workbook including a corrupt and a password-protected file; unit tests over fixtures with and without title rows; unit tests of inference over mixed sample columns.
