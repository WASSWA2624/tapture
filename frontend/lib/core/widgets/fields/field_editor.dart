import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';

import 'app_choice_field.dart';
import 'app_date_field.dart';
import 'app_multi_choice_field.dart';
import 'app_number_field.dart';
import 'app_switch_tile.dart';
import 'app_text_field.dart';
import 'choice.dart';
import 'field_value.dart';

/// Edits any field value through the editor the type registry names.
///
/// Review, records, capture and duplicate resolution reuse this widget so
/// validation and formatting stay identical. It never switches on the type:
/// [fieldEditorBindingsProvider] resolves the editor, validator and
/// normaliser from the registry.
class FieldEditor extends ConsumerWidget {
  /// Creates the editor for [field] showing [value].
  const FieldEditor({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  /// Column being edited. Core cannot import the template field type
  /// (FE-STR-04); callers map that type onto this record.
  final FieldEditorField field;

  /// Current value, including its source and audit history.
  final FieldValue value;

  /// Receives the edited value: source MANUAL, verified, previous in audit.
  final ValueChanged<FieldValue> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FieldEditorBindings bindings = ref.watch(fieldEditorBindingsProvider);
    final Result<void> check = bindings.validate(
      type: field.type,
      value: value.value,
      options: field.options,
      validation: field.validation,
    );
    final String? errorText = switch (check) {
      FailureResult<void>(:final Failure failure) => failure.message,
      Success<void>() => null,
    };
    final _EditorBuilder builder =
        _catalogue[bindings.kindOf(field.type)] ?? _readOnly;
    return builder(
      field: field,
      value: value.value,
      errorText: errorText,
      onChanged: (Object? next) {
        onChanged(
          _corrected(
            value,
            bindings.normalise(
              type: field.type,
              value: next,
              options: field.options,
              validation: field.validation,
            ),
          ),
        );
      },
    );
  }
}

/// Attributes [FieldEditor] needs from a field without importing the template
/// field type.
typedef FieldEditorField = ({
  String fieldKey,
  String label,
  String type,
  List<Object> options,
  String? helpText,
  String? unit,
  Map<String, Object?> validation,
});

/// Registry port: kind, validator and normaliser for one type name.
typedef FieldEditorBindings = ({
  String Function(String type) kindOf,
  Result<void> Function({
    required String type,
    required Object? value,
    required List<Object> options,
    required Map<String, Object?> validation,
  })
  validate,
  Object? Function({
    required String type,
    required Object? value,
    required List<Object> options,
    required Map<String, Object?> validation,
  })
  normalise,
});

/// Bindings that read [FieldTypeRegistry]. Tests and [main] override this.
final Provider<FieldEditorBindings> fieldEditorBindingsProvider =
    Provider<FieldEditorBindings>((Ref _) {
      throw StateError(
        'Override fieldEditorBindingsProvider with the template registry.',
      );
    });

typedef _EditorBuilder =
    Widget Function({
      required FieldEditorField field,
      required Object? value,
      required String? errorText,
      required ValueChanged<Object?> onChanged,
    });

final Map<String, _EditorBuilder> _catalogue = <String, _EditorBuilder>{
  'appTextField': _text,
  'appNumberField': _number,
  'appDateField': _date,
  'appSwitchTile': _toggle,
  'appChoiceField': _choice,
  'appMultiChoiceField': _multi,
};

Widget _text({
  required FieldEditorField field,
  required Object? value,
  required String? errorText,
  required ValueChanged<Object?> onChanged,
}) {
  return _BoundTextField(
    key: ValueKey<String>('field-editor-text-${field.fieldKey}'),
    label: field.label,
    helper: field.helpText,
    errorText: errorText,
    maxLines: field.type == 'longText' ? _longTextLines : 1,
    text: _asText(value),
    onChanged: onChanged,
  );
}

Widget _number({
  required FieldEditorField field,
  required Object? value,
  required String? errorText,
  required ValueChanged<Object?> onChanged,
}) {
  return AppNumberField(
    key: ValueKey<String>('field-editor-number-${field.fieldKey}'),
    label: field.label,
    unit: field.unit,
    min: _ruleNum(field, 'min'),
    max: _ruleNum(field, 'max'),
    decimal: field.type != 'number',
    onChanged: onChanged,
  );
}

Widget _date({
  required FieldEditorField field,
  required Object? value,
  required String? errorText,
  required ValueChanged<Object?> onChanged,
}) {
  return AppDateField(
    key: ValueKey<String>('field-editor-date-${field.fieldKey}'),
    label: field.label,
    mode: switch (field.type) {
      'time' => DateFieldMode.time,
      'dateTime' => DateFieldMode.dateTime,
      _ => DateFieldMode.date,
    },
    value: _asDate(value),
    onChanged: onChanged,
  );
}

Widget _toggle({
  required FieldEditorField field,
  required Object? value,
  required String? errorText,
  required ValueChanged<Object?> onChanged,
}) {
  return AppSwitchTile(
    key: ValueKey<String>('field-editor-toggle-${field.fieldKey}'),
    title: field.label,
    description: field.helpText,
    value: value == true,
    onChanged: onChanged,
  );
}

Widget _choice({
  required FieldEditorField field,
  required Object? value,
  required String? errorText,
  required ValueChanged<Object?> onChanged,
}) {
  return AppChoiceField<String>(
    key: ValueKey<String>('field-editor-choice-${field.fieldKey}'),
    label: field.label,
    options: _choices(field.options),
    value: _asText(value).isEmpty ? null : _asText(value),
    onChanged: onChanged,
  );
}

Widget _multi({
  required FieldEditorField field,
  required Object? value,
  required String? errorText,
  required ValueChanged<Object?> onChanged,
}) {
  return AppMultiChoiceField<String>(
    key: ValueKey<String>('field-editor-multi-${field.fieldKey}'),
    label: field.label,
    options: _choices(field.options),
    value: _asSet(value),
    onChanged: (Set<String> next) => onChanged(next.toList()),
  );
}

Widget _readOnly({
  required FieldEditorField field,
  required Object? value,
  required String? errorText,
  required ValueChanged<Object?> onChanged,
}) {
  return AppListTile(
    key: ValueKey<String>('field-editor-read-${field.fieldKey}'),
    title: field.label,
    subtitle: value == null ? null : _asText(value),
    dense: true,
  );
}

FieldValue _corrected(FieldValue current, Object? next) {
  return FieldValue(
    fieldKey: current.fieldKey,
    value: next,
    source: ValueSource.manual,
    verified: true,
    audit: <FieldAudit>[
      ...current.audit,
      (previousValue: current.value, newValue: next),
    ],
  );
}

class _BoundTextField extends StatefulWidget {
  const _BoundTextField({
    super.key,
    required this.label,
    required this.text,
    required this.onChanged,
    this.helper,
    this.errorText,
    this.maxLines = 1,
  });

  final String label;
  final String? helper;
  final String? errorText;
  final int maxLines;
  final String text;
  final ValueChanged<Object?> onChanged;

  @override
  State<_BoundTextField> createState() => _BoundTextFieldState();
}

class _BoundTextFieldState extends State<_BoundTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(_BoundTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && _controller.text != widget.text) {
      _controller.value = TextEditingValue(text: widget.text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: _controller,
      helper: widget.helper,
      errorText: widget.errorText,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
    );
  }
}

List<Choice<String>> _choices(List<Object> options) {
  final List<Choice<String>> rows = <Choice<String>>[];
  for (final Object option in options) {
    if (option is String) {
      final String trimmed = option.trim();
      if (trimmed.isNotEmpty) {
        rows.add(Choice<String>(trimmed, trimmed));
      }
      continue;
    }
    if (option is Map) {
      final String? code =
          option['code']?.toString() ?? option['label']?.toString();
      final String? label = option['label']?.toString() ?? code;
      if (code != null && label != null && code.isNotEmpty) {
        rows.add(Choice<String>(code, label));
      }
    }
  }
  return rows;
}

String _asText(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is Iterable<Object?>) {
    return value
        .whereType<Object>()
        .map((Object item) => item.toString())
        .join('\n');
  }
  return value.toString();
}

Set<String> _asSet(Object? value) {
  if (value is Set<String>) {
    return value;
  }
  if (value is Iterable<Object?>) {
    return <String>{
      for (final Object? item in value)
        if (item != null && item.toString().isNotEmpty) item.toString(),
    };
  }
  final String text = _asText(value);
  return text.isEmpty ? <String>{} : <String>{text};
}

DateTime? _asDate(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

num? _ruleNum(FieldEditorField field, String key) {
  final Object? raw = field.validation[key];
  if (raw is num) {
    return raw;
  }
  if (raw is String) {
    return num.tryParse(raw);
  }
  return null;
}

const int _longTextLines = 4;
