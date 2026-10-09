import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/validation/field_expression.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
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
    this.autoFillUnavailable = false,
    required this.stickable,
    required this.refine,
    required this.identity,
    required this.hidden,
    required this.knownKeys,
    required this.labelsByKey,
    required this.requiredWhenError,
    this.localizedRequiredWhenError,
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

  /// An existing source declaration this reader cannot safely activate.
  final bool autoFillUnavailable;
  final bool stickable;
  final bool refine;
  final bool identity;
  final bool hidden;
  final Iterable<String> knownKeys;
  final Map<String, String> labelsByKey;
  final String? requiredWhenError;

  /// Semantic error retained until the current locale renders the form.
  final LocalizedMessage? localizedRequiredWhenError;
  final ValueChanged<InputMode> onInputMode;
  final ValueChanged<AutoFill?> onAutoFill;
  final ValueChanged<bool> onStickable;
  final ValueChanged<bool> onRefine;
  final ValueChanged<bool> onIdentity;
  final ValueChanged<bool> onHidden;
  final ValueChanged<String> onRequiredWhenChanged;

  /// Refuses an expression that does not parse against this template's fields.
  static Result<void> validateRequiredWhen(
    String? expression,
    Iterable<String> knownKeys,
  ) {
    final String trimmed = expression?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const Success<void>(null);
    }
    final Result<FieldExpression> parsed = FieldExpression.parse(
      trimmed,
      knownKeys.toList(),
    );
    return switch (parsed) {
      Success<FieldExpression>() => const Success<void>(null),
      FailureResult<FieldExpression>(:final Failure failure) =>
        FailureResult<void>(failure),
    };
  }

  /// Plain-language reading of [expression], or empty when it is blank.
  static String previewRequiredWhen(
    String? expression,
    Map<String, String> labelsByKey, {
    LocalizedCopy? localizedCopy,
  }) {
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
    return (localizedCopy ?? Copy.english).fieldRequiredWhenPreview(reading);
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String preview = previewRequiredWhen(
      requiredWhen.text,
      labelsByKey,
      localizedCopy: localCopy,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: localCopy.fieldAdvanced, dense: true),
        AppListTile(
          title: localCopy.fieldSourceHelp,
          subtitle: localCopy.captureTemperatureUnavailable,
          leading: const Icon(AppIcons.info),
          dense: true,
          wrapText: true,
        ),
        AppTextField(
          label: localCopy.fieldDefaultValue,
          controller: defaultValue,
        ),
        AppTextField(label: localCopy.fieldUnit, controller: unit),
        AppTextField(label: localCopy.fieldHelp, controller: help),
        AppChoiceField<InputMode>(
          label: localCopy.fieldInputMode,
          value: inputMode,
          options: <Choice<InputMode>>[
            Choice<InputMode>(InputMode.any, localCopy.fieldInputAny),
            Choice<InputMode>(InputMode.manualOnly, localCopy.fieldInputManual),
            Choice<InputMode>(InputMode.aiAllowed, localCopy.fieldInputAi),
            Choice<InputMode>(InputMode.auto, localCopy.fieldInputAuto),
          ],
          onChanged: (InputMode? value) {
            if (value != null) {
              onInputMode(value);
            }
          },
        ),
        AppChoiceField<String>(
          label: localCopy.fieldAutoFill,
          value: autoFillUnavailable ? _unavailable : autoFill?.name ?? _none,
          options: <Choice<String>>[
            if (autoFillUnavailable)
              Choice<String>(_unavailable, localCopy.captureFieldUnavailable),
            Choice<String>(_none, localCopy.fieldAutoFillNone),
            for (final AutoFill source in AutoFill.values)
              Choice<String>(
                source.name,
                localCopy.fieldAutoFillLabel(source.name),
              ),
          ],
          onChanged: (String? value) {
            if (value == _unavailable) return;
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
          label: localCopy.fieldContextLevel,
          controller: contextLevel,
          keyboardType: TextInputType.number,
        ),
        AppSwitchTile(
          title: localCopy.fieldStickable,
          value: stickable,
          dense: true,
          onChanged: onStickable,
        ),
        AppSwitchTile(
          title: localCopy.fieldRefine,
          value: refine,
          dense: true,
          onChanged: onRefine,
        ),
        AppSwitchTile(
          title: localCopy.fieldIdentity,
          value: identity,
          dense: true,
          onChanged: onIdentity,
        ),
        AppTextField(
          label: localCopy.fieldRequiredWhen,
          controller: requiredWhen,
          errorText: localCopy.stateText(
            localizedRequiredWhenError,
            requiredWhenError,
          ),
          helper: requiredWhenError == null && preview.isNotEmpty
              ? preview
              : null,
          onChanged: onRequiredWhenChanged,
        ),
        AppSwitchTile(
          title: localCopy.fieldHidden,
          description: localCopy.fieldHiddenHelp,
          value: hidden,
          dense: true,
          onChanged: onHidden,
        ),
      ],
    );
  }
}

const String _none = 'none';
const String _unavailable = 'unavailable';
