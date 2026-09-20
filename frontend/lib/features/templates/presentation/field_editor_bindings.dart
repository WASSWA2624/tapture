import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';

import '../domain/field_def.dart';
import '../domain/field_type_registry.dart';

/// Registry port [FieldEditor] reads. One implementation so every screen
/// resolves editors the same way.
const FieldEditorBindings templateFieldEditorBindings = (
  kindOf: _kindOf,
  validate: _validate,
  normalise: _normalise,
);

/// Maps a template [FieldDef] onto the core record [FieldEditor] accepts.
FieldEditorField fieldEditorField(FieldDef field) {
  return (
    fieldKey: field.fieldKey,
    label: field.label,
    type: field.type.name,
    options: field.options,
    helpText: field.helpText,
    unit: field.unit,
    validation: field.validation,
  );
}

String _kindOf(String type) {
  return FieldTypeRegistry.of(_type(type)).editor.name;
}

Result<void> _validate({
  required String type,
  required Object? value,
  required List<Object> options,
  required Map<String, Object?> validation,
}) {
  return FieldTypeRegistry.validate(
    type: _type(type),
    value: value,
    field: _draft(type: type, options: options, validation: validation),
  );
}

Object? _normalise({
  required String type,
  required Object? value,
  required List<Object> options,
  required Map<String, Object?> validation,
}) {
  return FieldTypeRegistry.normalise(
    type: _type(type),
    value: value,
    field: _draft(type: type, options: options, validation: validation),
  );
}

FieldDef _draft({
  required String type,
  required List<Object> options,
  required Map<String, Object?> validation,
}) {
  return FieldDef(
    fieldKey: 'field',
    label: 'field',
    type: _type(type),
    options: options,
    validation: validation,
  );
}

FieldType _type(String name) {
  for (final FieldType type in FieldType.values) {
    if (type.name == name) {
      return type;
    }
  }
  return FieldType.text;
}
