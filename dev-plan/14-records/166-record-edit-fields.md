# 166 — Edit a saved record: fields, photos and template

**Phase** 14 · Records  |  **Depends on** [097](../09-templates/097-field-editor-inline.md), [099](../09-templates/099-template-versioning.md), [123](../12-capture/123-camera-shutter.md), [128](../12-capture/128-photo-delete.md), [165](165-record-detail.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Everything about a saved record can still change: values through the inline field editor, photos added or removed
long after capture, and the template swapped with a re-map by field key — each with its audit entry and its status
consequence.

## Files

- `frontend/lib/features/records/presentation/record_edit_screen.dart` (new)
- `frontend/lib/features/records/presentation/record_photos_editor.dart` (new)
- `frontend/lib/features/records/presentation/record_template_change.dart` (new)

## Steps

1. Editing an approved record returns it to NEEDS_REVIEW and writes an audit entry holding the previous and new
   value.
2. Adding a photo offers re-analysis; removing one flags every value whose evidence has gone instead of deleting the
   value.
3. Changing template shows what maps by field key, what does not and what will be retired, before applying; unmapped
   values are kept as retired.

## Constraints

- Values are edited through the inline field editor of task 097, so validation and formatting stay identical to
  capture (FE-CONS-01).

## Definition of done

- [ ] Nothing about a record is permanently frozen.
- [ ] Values are never silently deleted when their evidence is removed, and unmapped values are retained as retired.
- [ ] Tests: test of the status transition and audit entry on edit; test of the evidence-removed flag; widget test of
      `record_template_change.dart`, including its empty and failure states.
