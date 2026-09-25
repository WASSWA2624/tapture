import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import '../domain/field_def.dart';
import '../domain/field_type_registry.dart';

/// Pattern, length, range and required-with rules, with a live test box.
class FieldValidationEditor extends StatefulWidget {
  /// Creates the editor. [validation] is the §12.2 map on the field.
  const FieldValidationEditor({
    super.key,
    required this.validation,
    required this.type,
    required this.onChanged,
    this.fieldKeys = const <String>[],
    this.failure,
  });

  /// Stored rules. Empty means no rule is set.
  final Map<String, Object?> validation;

  /// Type whose registry validator the live box runs.
  final FieldType type;

  /// Known keys [requiredWith] may name.
  final List<String> fieldKeys;

  /// Called with a new map after any edit.
  final ValueChanged<Map<String, Object?>> onChanged;

  /// Optional failure the parent already knows, for the empty/failure tests.
  final Failure? failure;

  /// Ready-made patterns: serial, asset tag, registration.
  static const Map<String, String> readyMade = <String, String>{
    _serial: r'^[A-Za-z0-9]+(-[A-Za-z0-9]+)*$',
    _assetTag: r'^[A-Za-z]{2,}[-_/]?[0-9]{3,}$',
    _registration: r'^[A-Za-z]{2,3}\s?[0-9]{3,4}[A-Za-z]{0,3}$',
  };

  /// Runs the registry validator for [type] against [sample].
  static Result<void> testValue({
    required FieldType type,
    required Map<String, Object?> validation,
    required Object? sample,
  }) {
    return FieldTypeRegistry.validate(
      type: type,
      value: sample,
      field: FieldDef(
        fieldKey: 'sample',
        label: 'Sample',
        type: type,
        validation: validation,
      ),
    );
  }

  @override
  State<FieldValidationEditor> createState() => _FieldValidationEditorState();
}

class _FieldValidationEditorState extends State<FieldValidationEditor> {
  late final TextEditingController _custom = TextEditingController(
    text: _customOf(widget.validation),
  );
  late final TextEditingController _minLength = TextEditingController(
    text: _textOf(widget.validation, _minLengthKey, _minLengthSnake),
  );
  late final TextEditingController _maxLength = TextEditingController(
    text: _textOf(widget.validation, _maxLengthKey, _maxLengthSnake),
  );
  late final TextEditingController _min = TextEditingController(
    text: _textOf(widget.validation, _minKey, _minKey),
  );
  late final TextEditingController _max = TextEditingController(
    text: _textOf(widget.validation, _maxKey, _maxKey),
  );
  late final TextEditingController _requiredWith = TextEditingController(
    text: _textOf(widget.validation, _requiredWithKey, _requiredWithSnake),
  );
  final TextEditingController _sample = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    _minLength.dispose();
    _maxLength.dispose();
    _min.dispose();
    _max.dispose();
    _requiredWith.dispose();
    _sample.dispose();
    super.dispose();
  }

  bool get _isEmpty => widget.validation.isEmpty;

  String get _kind {
    final String? pattern = widget.validation[_patternKey] as String?;
    if (pattern == null || pattern.isEmpty) {
      return _none;
    }
    for (final MapEntry<String, String> entry
        in FieldValidationEditor.readyMade.entries) {
      if (entry.value == pattern) {
        return entry.key;
      }
    }
    return _customKind;
  }

  @override
  Widget build(BuildContext context) {
    final Failure? failure = widget.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: Copy.fieldValidationTitle, dense: true),
        if (_isEmpty)
          const AppEmptyState(
            icon: AppIcons.rules,
            headline: Copy.fieldValidationEmptyHeadline,
            message: Copy.fieldValidationEmptyMessage,
          ),
        if (failure != null) AppErrorState(failure: failure),
        AppChoiceField<String>(
          label: Copy.fieldPattern,
          value: _kind,
          options: const <Choice<String>>[
            Choice<String>(_none, Copy.fieldPatternNone),
            Choice<String>(_serial, Copy.fieldPatternSerial),
            Choice<String>(_assetTag, Copy.fieldPatternAssetTag),
            Choice<String>(_registration, Copy.fieldPatternRegistration),
            Choice<String>(_customKind, Copy.fieldPatternCustom),
          ],
          onChanged: _setKind,
        ),
        if (_kind == _customKind)
          AppTextField(
            label: Copy.fieldPatternCustom,
            controller: _custom,
            onChanged: (_) => _emit(),
          ),
        AppTextField(
          label: Copy.fieldMinLength,
          controller: _minLength,
          keyboardType: TextInputType.number,
          onChanged: (_) => _emit(),
        ),
        AppTextField(
          label: Copy.fieldMaxLength,
          controller: _maxLength,
          keyboardType: TextInputType.number,
          onChanged: (_) => _emit(),
        ),
        AppTextField(
          label: Copy.fieldRangeMin,
          controller: _min,
          keyboardType: TextInputType.number,
          onChanged: (_) => _emit(),
        ),
        AppTextField(
          label: Copy.fieldRangeMax,
          controller: _max,
          keyboardType: TextInputType.number,
          onChanged: (_) => _emit(),
        ),
        AppTextField(
          label: Copy.fieldRequiredWith,
          controller: _requiredWith,
          onChanged: (_) => _emit(),
        ),
        ListenableBuilder(
          listenable: _sample,
          builder: (BuildContext context, Widget? _) {
            final String? testError = _errorFor(_sample.text);
            return AppTextField(
              label: Copy.fieldPatternTest,
              controller: _sample,
              errorText: testError,
              helper: testError == null && _sample.text.isNotEmpty
                  ? Copy.fieldPatternTestPass
                  : null,
            );
          },
        ),
      ],
    );
  }

  void _setKind(String? kind) {
    final String next = kind ?? _none;
    if (next != _customKind) {
      _custom.clear();
    } else if (_custom.text.isEmpty) {
      _custom.text = widget.validation[_patternKey] as String? ?? '';
    }
    _emit(kind: next);
  }

  void _emit({String? kind}) {
    final String chosen = kind ?? _kind;
    final Map<String, Object?> next = <String, Object?>{};
    final String? pattern = switch (chosen) {
      _none => null,
      _customKind => _custom.text.trim().isEmpty ? null : _custom.text.trim(),
      _ => FieldValidationEditor.readyMade[chosen],
    };
    if (pattern != null) {
      next[_patternKey] = pattern;
    }
    _putInt(next, _minLengthKey, _minLength.text);
    _putInt(next, _maxLengthKey, _maxLength.text);
    _putNum(next, _minKey, _min.text);
    _putNum(next, _maxKey, _max.text);
    final String requiredWith = _requiredWith.text.trim();
    if (requiredWith.isNotEmpty &&
        (widget.fieldKeys.isEmpty || widget.fieldKeys.contains(requiredWith))) {
      next[_requiredWithKey] = requiredWith;
    }
    widget.onChanged(next);
  }

  String? _errorFor(String sample) {
    if (sample.trim().isEmpty) {
      return null;
    }
    final Result<void> result = FieldValidationEditor.testValue(
      type: widget.type,
      validation: widget.validation,
      sample: sample,
    );
    return switch (result) {
      Success<void>() => null,
      FailureResult<void>(:final Failure failure) => failure.message,
    };
  }
}

void _putInt(Map<String, Object?> into, String key, String raw) {
  final int? value = int.tryParse(raw.trim());
  if (value != null) {
    into[key] = value;
  }
}

void _putNum(Map<String, Object?> into, String key, String raw) {
  final num? value = num.tryParse(raw.trim());
  if (value != null) {
    into[key] = value;
  }
}

String _textOf(Map<String, Object?> map, String camel, String snake) {
  return '${map[camel] ?? map[snake] ?? ''}';
}

String _customOf(Map<String, Object?> map) {
  final String? pattern = map[_patternKey] as String?;
  if (pattern == null) {
    return '';
  }
  if (FieldValidationEditor.readyMade.containsValue(pattern)) {
    return '';
  }
  return pattern;
}

const String _none = 'none';
const String _serial = 'serial';
const String _assetTag = 'asset_tag';
const String _registration = 'registration';
const String _customKind = 'custom';
const String _patternKey = 'pattern';
const String _minLengthKey = 'minLength';
const String _minLengthSnake = 'min_length';
const String _maxLengthKey = 'maxLength';
const String _maxLengthSnake = 'max_length';
const String _minKey = 'min';
const String _maxKey = 'max';
const String _requiredWithKey = 'requiredWith';
const String _requiredWithSnake = 'required_with';
