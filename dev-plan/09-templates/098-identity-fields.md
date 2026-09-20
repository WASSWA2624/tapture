# 098 — Identity fields and output column mapping

**Phase** 09 · Templates  |  **Depends on** [088](088-template-model.md), [094](094-field-list-editor.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two template-level column settings reached from the field list: which fields identify a record for duplicate
detection, and which spreadsheet column or generated header each field writes to on export.

## Files

- `frontend/lib/features/templates/presentation/identity_fields_screen.dart` (new)
- `frontend/lib/features/templates/presentation/output_mapping_screen.dart` (new)

## Steps

1. Identity is a multi-select over the template's existing fields, with one sentence explaining what it changes.
2. A shipped template arrives with `identity_fields` already set (§13.5); this screen edits that set, it does not
   invent it.
3. Output columns auto-assign for templates built in the app, and stay manually overridable for templates imported
   from a workbook, where the column letters already exist.
4. Refuse a mapping in which two fields claim the same column.

## Constraints

- Both screens write through the template repository and bump the version like any other structural change (§18).

## Definition of done

- [x] Duplicate detection has an explicit, visible configuration rather than an implied one.
- [x] Two fields cannot claim the same output column.
- [x] Tests: widget test of `identity_fields_screen.dart` covering empty and failure states; unit test rejecting a duplicate output column.
