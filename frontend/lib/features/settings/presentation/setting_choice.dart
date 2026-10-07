import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

/// One enumerated setting on a settings page: its name, every choice with
/// the current one marked, and one plain line saying what it changes.
///
/// Sits on the same gutter as the page's rows (`AppPage(inset: false)`), so
/// a choice lines up with the switches and tiles around it. Settings never
/// cycle a value on tap (FE-CONS-10).
class SettingChoice<T> extends StatelessWidget {
  /// Creates a setting row for [options].
  const SettingChoice({
    super.key,
    required this.label,
    required this.effect,
    required this.options,
    required this.value,
    required this.onChanged,
    this.alwaysSheet = false,
  });

  /// The setting's name, also the control's semantic label.
  final String label;

  /// What choosing a value changes, in one sentence.
  final String effect;

  /// Every value, in the order shown.
  final List<Choice<T>> options;

  /// The stored value.
  final T value;

  /// Called with a newly picked value.
  final ValueChanged<T> onChanged;

  /// Keeps a compact selected value and opens the searchable shared selector.
  final bool alwaysSheet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x4,
        vertical: Space.x2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppChoiceField<T>(
            label: label,
            value: value,
            options: options,
            alwaysSheet: alwaysSheet,
            onChanged: (T? next) {
              if (next != null && next != value) {
                onChanged(next);
              }
            },
          ),
          const SizedBox(height: Space.x1),
          Text(
            effect,
            style: AppText.caption.copyWith(color: context.colors.onSurface),
          ),
        ],
      ),
    );
  }
}
