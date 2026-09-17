# 198 — Write into a copy of the client workbook

**Phase** 18 · Export  |  **Depends on** [102](../09-templates/102-xlsx-mapping-screen.md), [154](../13-processing/154-row-matching.md), [197](197-xlsx-writer.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

An export against an imported workbook copies the stored template, writes into the copy's mapped sheet and columns and
leaves the stored file untouched. Where the template already has predefined rows, values land in the matched row
instead of being appended.

## Files

- `frontend/lib/core/export/xlsx_template_copy.dart` (new)
- `frontend/lib/core/export/xlsx_row_targeting.dart` (new)

## Steps

1. Copy the stored template file to the export folder, then open only the copy.
2. Resolve each record to a row through the matcher of 285; append only when the template has no predefined rows.
3. Leave a row that never matched visibly empty or marked not found, and count those rows for the export summary.
4. Report in the export summary every workbook feature the library could not preserve.

## Constraints

- Validate the chosen library against a real client workbook before committing to it; formatting loss is a
  correctness failure here, not a cosmetic one.
- The stored template is read-only input; nothing in this task opens it for writing (FE-SEC-08).

## Definition of done

- [ ] The stored template file is byte-identical after every export.
- [ ] Client formatting, formulas and sheet order survive in the copy, and anything lost is named in the summary.
- [ ] A predefined row that no record matched stays visibly empty or marked not found, and is counted.
- [ ] Tests: unit tests of `xlsx_template_copy.dart` hashing the template before and after a write, and of `xlsx_row_targeting.dart` over matched, unmatched and duplicate-match rows.
