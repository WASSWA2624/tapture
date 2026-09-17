# 102 — Confirm the column mapping and create the template

**Phase** 09 · Templates  |  **Depends on** [038](../03-design-system/038-app-card.md), [066](../05-file-storage/066-project-folder-service.md), [088](088-template-model.md), [101](101-xlsx-read-workbook.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The two-column confirmation screen from the specification — spreadsheet column against proposed field, with its type
and rule — and, on confirm, the template it persists alongside a byte-identical copy of the original workbook in the
project's `templates/` folder.

## Files

- `frontend/lib/features/templates/presentation/xlsx_mapping_screen.dart` (new)
- `frontend/lib/features/templates/data/xlsx_template_import.dart` (new)

## Steps

1. Show one row per spreadsheet column: source header on the left, proposed field, type and rule on the right. Every
   row is editable and every row can be skipped.
2. Write nothing — no template, no copied file — until the user confirms.
3. Persist the sheet name, header row and column letters on the template, so export writes back into the same cells.
4. Copy the chosen file into `templates/` unmodified, through the project folder service.

## Constraints

- The copied workbook is raw evidence: written once, never rewritten in place (FE-SEC-08).
- Rows use `AppListTile`; the screen invents no table widget (FE-CONS-06).

## Definition of done

- [ ] Nothing is imported until the user confirms the mapping.
- [ ] The original file on disk is byte-identical to the one the user chose.
- [ ] A template created this way exports back into the same sheet, header row and column letters.
- [ ] Tests: widget test of `xlsx_mapping_screen.dart` covering empty and failure states and the skip path; hash comparison test of the workbook before and after import.
