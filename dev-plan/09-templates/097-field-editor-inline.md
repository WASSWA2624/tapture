# 097 — Field editor widget

**Phase** 09 · Templates  |  **Depends on** [035](../03-design-system/035-app-text-field.md), [089](089-field-type-registry.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The one widget that edits any field value using the editor its type declares in the registry, reused by review,
records, capture and duplicate resolution. No feature builds a second one.

## Files

- `frontend/lib/core/widgets/fields/field_editor.dart` (new)

## Contract

```dart
class FieldEditor extends ConsumerWidget {
  final FieldDef field;
  final FieldValue value;
  final ValueChanged<FieldValue> onChanged;
}
```

## Steps

1. Resolve the editor, validator and normaliser from the field type registry; never switch on the type here.
2. On edit, set source MANUAL, mark the value verified, and write an audit entry carrying the previous value.

## Constraints

- Lives in `core/widgets/`, so it imports no feature (FE-STR-04).
- The audit entry is written on every change, including a change back to the original value (FE-SEC-09).

## Definition of done

- [ ] Every correction is recorded with what it replaced.
- [ ] Editing through this widget yields the same behaviour in review, records, capture and duplicate resolution.
- [ ] Tests: widget test asserting the audit row and the MANUAL source after an edit, across at least one text, one choice and one date field.
- [ ] Contract above is implemented exactly, with nothing else made public.
