import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/field_def.dart';

/// Every §12.2 attribute the three-question add flow defaults, plus
/// `required_when` and `hidden`.
class FieldAdvancedSection extends StatelessWidget {
  /// Creates the section. Text fields are owned by the parent so collapsing
  /// Advanced cannot drop what was typed.
  const FieldAdvancedSection({
    super.key,
    required this.defaultValue,
    required this.unit,
    required this.help,
    required this.requiredWhen,
    required this.contextLevel,
    required this.inputMode,
    required this.autoFill,
    required this.stickable,
    required this.refine,
    required this.identity,
    required this.hidden,
    required this.knownKeys,
    required this.labelsByKey,
    required this.requiredWhenError,
    required this.onInputMode,
    required this.onAutoFill,
    required this.onStickable,
    required this.onRefine,
    required this.onIdentity,
    required this.onHidden,
    required this.onRequiredWhenChanged,
  });

  final TextEditingController defaultValue;
  final TextEditingController unit;
  final TextEditingController help;
  final TextEditingController requiredWhen;
  final TextEditingController contextLevel;
  final InputMode inputMode;
  final AutoFill? autoFill;
  final bool stickable;
  final bool refine;
  final bool identity;
  final bool hidden;
  final Iterable<String> knownKeys;
  final Map<String, String> labelsByKey;
  final String? requiredWhenError;
  final ValueChanged<InputMode> onInputMode;
  final ValueChanged<AutoFill?> onAutoFill;
  final ValueChanged<bool> onStickable;
  final ValueChanged<bool> onRefine;
  final ValueChanged<bool> onIdentity;
  final ValueChanged<bool> onHidden;
  final ValueChanged<String> onRequiredWhenChanged;

  /// Reserved words a `required_when` expression may use.
  static const Set<String> reserved = <String>{
    'true',
    'false',
    'and',
    'or',
    'not',
    'null',
  };

  /// Refuses an expression that names a field this template does not have.
  static Result<void> validateRequiredWhen(
    String? expression,
    Iterable<String> knownKeys,
  ) {
    final String trimmed = expression?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const Success<void>(null);
    }
    final Set<String> keys = knownKeys.toSet();
    for (final RegExpMatch match in _name.allMatches(trimmed)) {
      final String name = match.group(0)!;
      if (reserved.contains(name) || keys.contains(name)) {
        continue;
      }
      return FailureResult<void>(
        ValidationFailure(
          message:
              'Required when names "$name", which this template does not have.',
          recoveryAction: 'Pick a field on this template, or clear the rule.',
        ),
      );
    }
    return const Success<void>(null);
  }

  /// Plain-language reading of [expression], or empty when it is blank.
  static String previewRequiredWhen(
    String? expression,
    Map<String, String> labelsByKey,
  ) {
    final String trimmed = expression?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }
    String reading = trimmed;
    for (final MapEntry<String, String> entry in labelsByKey.entries) {
      reading = reading.replaceAll(entry.key, entry.value);
    }
    reading = reading
        .replaceAll('==', 'is')
        .replaceAll('!=', 'is not')
        .replaceAll('true', 'yes')
        .replaceAll('false', 'no');
    return Copy.fieldRequiredWhenPreview(reading);
  }

  @override
  Widget build(BuildContext context) {
    final String preview = previewRequiredWhen(requiredWhen.text, labelsByKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: Copy.fieldAdvanced, dense: true),
        AppTextField(label: Copy.fieldDefaultValue, controller: defaultValue),
        AppTextField(label: Copy.fieldUnit, controller: unit),
        AppTextField(label: Copy.fieldHelp, controller: help),
        AppChoiceField<InputMode>(
          label: Copy.fieldInputMode,
          value: inputMode,
          options: const <Choice<InputMode>>[
            Choice<InputMode>(InputMode.any, Copy.fieldInputAny),
            Choice<InputMode>(InputMode.manualOnly, Copy.fieldInputManual),
            Choice<InputMode>(InputMode.aiAllowed, Copy.fieldInputAi),
            Choice<InputMode>(InputMode.auto, Copy.fieldInputAuto),
          ],
          onChanged: (InputMode? value) {
            if (value != null) {
              onInputMode(value);
            }
          },
        ),
        AppChoiceField<String>(
          label: Copy.fieldAutoFill,
          value: autoFill?.name ?? _none,
          options: <Choice<String>>[
            const Choice<String>(_none, Copy.fieldAutoFillNone),
            for (final AutoFill source in AutoFill.values)
              Choice<String>(source.name, Copy.fieldAutoFillLabel(source.name)),
          ],
          onChanged: (String? value) {
            if (value == null || value == _none) {
              onAutoFill(null);
              return;
            }
            for (final AutoFill source in AutoFill.values) {
              if (source.name == value) {
                onAutoFill(source);
                return;
              }
            }
          },
        ),
        AppTextField(
          label: Copy.fieldContextLevel,
          controller: contextLevel,
          keyboardType: TextInputType.number,
        ),
        AppSwitchTile(
          title: Copy.fieldStickable,
          value: stickable,
          dense: true,
          onChanged: onStickable,
        ),
        AppSwitchTile(
          title: Copy.fieldRefine,
          value: refine,
          dense: true,
          onChanged: onRefine,
        ),
        AppSwitchTile(
          title: Copy.fieldIdentity,
          value: identity,
          dense: true,
          onChanged: onIdentity,
        ),
        AppTextField(
          label: Copy.fieldRequiredWhen,
          controller: requiredWhen,
          errorText: requiredWhenError,
          helper: requiredWhenError == null && preview.isNotEmpty
              ? preview
              : null,
          onChanged: onRequiredWhenChanged,
        ),
        AppSwitchTile(
          title: Copy.fieldHidden,
          description: Copy.fieldHiddenHelp,
          value: hidden,
          dense: true,
          onChanged: onHidden,
        ),
      ],
    );
  }
}

final RegExp _name = RegExp(r'\b[a-z][a-z0-9_]*\b');

const String _none = 'none';
