import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/consent_stamp.dart';
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

/// The value [FieldEditor] shows for the stored [text] of a [type] field.
Object? editorValueOf(FieldType type, String text) {
  if (text.isEmpty) return null;
  return switch (type) {
    FieldType.number ||
    FieldType.decimal ||
    FieldType.currency ||
    FieldType.percentage => num.tryParse(text) ?? text,
    FieldType.time => _timeOf(text) ?? text,
    FieldType.date || FieldType.dateTime => DateTime.tryParse(text) ?? text,
    FieldType.boolean => text == 'true',
    FieldType.consent => ConsentStamp.parse(text)?.toJson(),
    FieldType.multiChoice => <String>[
      for (final String part in text.split(_listSeparator))
        if (part.trim().isNotEmpty) part.trim(),
    ],
    _ => text,
  };
}

/// Stored editor text: ISO dates, `HH:mm` times and comma-separated choices.
String storedTextOf(FieldType type, Object? value) {
  if (value == null) return '';
  if (type == FieldType.consent) {
    final ConsentStamp? stamp = ConsentStamp.parse(value);
    return stamp == null ? '' : jsonEncode(stamp.toJson());
  }
  if (value is DateTime) {
    return switch (type) {
      FieldType.date => DateFormat('yyyy-MM-dd').format(value),
      FieldType.time => DateFormat('HH:mm').format(value),
      _ => value.toIso8601String(),
    };
  }
  if (value is Iterable<Object?>) {
    return value
        .whereType<Object>()
        .map((Object choice) => choice.toString())
        .join(_listSeparator);
  }
  return value.toString();
}

DateTime? _timeOf(String text) {
  final List<String> parts = text.split(':');
  if (parts.length < 2) return DateTime.tryParse(text);
  final int? hour = int.tryParse(parts[0]);
  final int? minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return DateTime(2000, 1, 1, hour, minute);
}

const String _listSeparator = ', ';

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
