import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// The operator's choice when detection cannot decide.
///
/// Two or three large buttons, plus a pin for the current place so the
/// question is asked once per room.
class TemplateChoiceSheet extends StatefulWidget {
  /// Creates the sheet body. [failure] replaces the choices.
  const TemplateChoiceSheet({
    super.key,
    required this.options,
    this.failure,
    this.onChosen,
  });

  /// Labels, at most three, plus room for "Something else" when shorter.
  final List<String> options;

  /// Set when the choices could not be loaded.
  final Failure? failure;

  /// Called with the label, or null for something else, and the pin.
  final void Function(String? template, bool pin)? onChosen;

  @override
  State<TemplateChoiceSheet> createState() => _TemplateChoiceSheetState();
}

class _TemplateChoiceSheetState extends State<TemplateChoiceSheet> {
  bool _pin = true;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = widget.failure;
    if (failure != null) {
      return AppErrorState(failure: failure);
    }
    if (widget.options.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.category,
        headline: Copy.templateChoiceEmptyHeadline,
        message: Copy.templateChoiceEmptyMessage,
      );
    }
    final List<String> shown = widget.options.length > 3
        ? widget.options.sublist(0, 3)
        : widget.options;
    return ListView(
      children: <Widget>[
        for (final String option in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.x2),
            child: AppButton(
              label: option,
              onPressed: () => widget.onChosen?.call(option, _pin),
            ),
          ),
        if (shown.length < 3)
          AppButton(
            label: Copy.templateChoiceOther,
            variant: AppButtonVariant.secondary,
            onPressed: () => widget.onChosen?.call(null, _pin),
          ),
        AppSwitchTile.checkbox(
          title: Copy.templateChoicePin,
          value: _pin,
          onChanged: (bool value) => setState(() => _pin = value),
        ),
      ],
    );
  }
}

/// Opens [TemplateChoiceSheet] through the shared sheet.
Future<({String? template, bool pin})?> showTemplateChoice(
  BuildContext context, {
  required List<String> options,
  Failure? failure,
}) {
  return showAppSheet<({String? template, bool pin})>(
    context,
    title: Copy.templateChoiceTitle,
    builder: (BuildContext sheetContext) {
      return TemplateChoiceSheet(
        options: options,
        failure: failure,
        onChosen: (String? template, bool pin) {
          Navigator.of(sheetContext).pop((template: template, pin: pin));
        },
      );
    },
  );
}
