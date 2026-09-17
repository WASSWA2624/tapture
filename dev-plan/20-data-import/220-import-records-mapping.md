# 220 — Map spreadsheet columns to template fields

**Phase** 20 · Data import  |  **Depends on** [088](../09-templates/088-template-model.md), [102](../09-templates/102-xlsx-mapping-screen.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The mapping screen of the template phase, driven to a second purpose: mapping a workbook's columns onto an existing
template's fields so its rows can become records, with identity fields mandatory before the flow continues.

## Files

- `frontend/lib/features/import/presentation/record_mapping_screen.dart` (new)

## Steps

1. Preselect mappings by header name against the target template's field keys and labels, leaving the operator to
   confirm.
2. Block continuing until every field the template marks as identity is mapped, and say which one is missing.
3. Show the first rows as they would be interpreted, so a wrong mapping is visible before import.

## Constraints

- Reuse the workbook reader, header detection and type inference of 180 unchanged; a second copy of any of them is a
  defect (FE-CONS-02, FE-STR-09).

## Definition of done

- [ ] The same mapping interface serves both template creation and record import, with no duplicated reader or inference.
- [ ] The flow cannot continue while an identity field is unmapped, and names the field that is missing.
- [ ] Tests: widget test of `record_mapping_screen.dart` covering preselected mappings, a blocked continue with an unmapped identity field, and the four states.
