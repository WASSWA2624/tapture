# 197 — XLSX writer core, column pairs and sheets

**Phase** 18 · Export  |  **Depends on** [005](../01-orchestration/005-dependency-allowlist.md), [024](../02-foundation/024-hashing-service.md), [088](../09-templates/088-template-model.md), [181](../16-review/181-raw-refined-toggle.md), [195](195-value-formatter.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A workbook writer that runs on an isolate and reports progress, laying records out as the project requires: one sheet
per template for multi-template projects, and a companion column beside every refined field so the raw and refined
values both survive.

## Files

- `frontend/lib/core/export/xlsx_writer.dart` (new)
- `frontend/lib/core/export/xlsx_refined_columns.dart` (new)
- `frontend/lib/core/export/xlsx_multi_sheet.dart` (new)

## Contract

```dart
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
```

## Steps

1. Build a `SheetPlan` per template first: unique, valid sheet names derived from template names, then the column
   order from the field keys.
2. Insert each refined companion column next to its raw column with a clear header suffix, without shifting any
   mapping already recorded for that template.
3. Append rows after the last used row of the sheet, writing native cell types through `ExportValueFormatter.typed`.
4. Run the whole write inside the isolate runner of 033, streaming progress per record batch.

## Constraints

- The UI thread renders no cell and holds no workbook (FE-PERF-02); the file is streamed, not assembled in memory
  (FE-PERF-07).
- The spreadsheet package is the one allowed by 005; no second XLSX dependency is added.

## Definition of done

- [ ] A five-thousand-record export finishes in under thirty seconds with visible progress and no dropped frames.
- [ ] A multi-template project produces one validly named sheet per template, with no name collisions.
- [ ] Raw and refined values appear side by side and neither is lost.
- [ ] Tests: unit tests of `xlsx_writer.dart` reopening the output through a spreadsheet reader and asserting cell types, headers of both column pairs and sheet names; a measured test backing the thirty-second claim (FE-TEST-09).

## Out of scope

- Writing into a customer's own workbook; that is task 198.
- Photo columns and the photo index sheet; those are task 199.
