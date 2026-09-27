import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/templates/templates.dart';

import 'record_edit_sheet.dart';

/// One record field typed by hand: the input its template type names
/// (a date picker, a number, a choice…) through the shared [FieldEditor], or
/// a text field for a stored value the template no longer declares
/// (FBK0000162). The value travels as the text a record field stores.
class RecordFieldInput extends StatelessWidget {
  /// Creates the input for [entry], showing [text].
  const RecordFieldInput({
    required this.entry,
    required this.text,
    required this.onChanged,
    this.controller,
    super.key,
  });

  /// The field being filled.
  final RecordEditEntry entry;

  /// Its current text.
  final String text;

  /// Receives the new text.
  final ValueChanged<String> onChanged;

  /// Holds the text of an undeclared field between rebuilds.
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final FieldDef? field = entry.field;
    if (field == null) {
      return AppTextField(
        label: entry.label,
        controller: controller ?? TextEditingController(text: text),
        onChanged: onChanged,
      );
    }
    return FieldEditor(
      key: ValueKey<String>('record-field-input-${entry.fieldKey}'),
      field: fieldEditorField(
        field.label.isEmpty ? field.copyWith(label: field.fieldKey) : field,
      ),
      value: FieldValue(
        fieldKey: field.fieldKey,
        value: editorValueOf(field.type, text),
        source: ValueSource.manual,
        verified: false,
        audit: const <FieldAudit>[],
      ),
      onChanged: (FieldValue next) =>
          onChanged(storedTextOf(field.type, next.value)),
    );
  }
}

/// The value [FieldEditor] shows for the stored [text] of a [type] field.
Object? editorValueOf(FieldType type, String text) {
  if (text.isEmpty) {
    return null;
  }
  return switch (type) {
    FieldType.number ||
    FieldType.decimal ||
    FieldType.currency ||
    FieldType.percentage => num.tryParse(text) ?? text,
    FieldType.time => _timeOf(text) ?? text,
    FieldType.date || FieldType.dateTime => DateTime.tryParse(text) ?? text,
    FieldType.boolean => text == 'true',
    FieldType.multiChoice => <String>[
      for (final String part in text.split(_listSeparator))
        if (part.trim().isNotEmpty) part.trim(),
    ],
    _ => text,
  };
}

/// The text a record field stores for [value] from a [type] field's editor:
/// dates as ISO-8601, several choices joined by commas.
String storedTextOf(FieldType type, Object? value) {
  if (value == null) {
    return '';
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
        .map((Object item) => item.toString())
        .join(_listSeparator);
  }
  return value.toString();
}

const String _listSeparator = ', ';

/// A stored `HH:mm` time as a [DateTime] on an arbitrary day.
DateTime? _timeOf(String text) {
  final List<String> parts = text.split(':');
  if (parts.length < 2) {
    return DateTime.tryParse(text);
  }
  final int? hour = int.tryParse(parts[0]);
  final int? minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  return DateTime(2000, 1, 1, hour, minute);
}
