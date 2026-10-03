import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import 'template_choice_pin.dart';

/// The operator's choice when detection cannot decide.
///
/// Up to three template rows, then Something else, plus a pin for the
/// current place so the question is asked once per room. Rows follow the
/// shared choice sheet: a tap answers (FE-CONS-01).
class TemplateChoiceSheet extends ConsumerWidget {
  /// Creates the sheet body. [failure] replaces the choices.
  const TemplateChoiceSheet({
    super.key,
    required this.options,
    this.failure,
    this.onChosen,
  });

  /// Template labels; the first three are offered.
  final List<String> options;

  /// Set when the choices could not be loaded.
  final Failure? failure;

  /// Called with the label, or null for something else, and the pin.
  final void Function(String? template, bool pin)? onChosen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool pin = ref.watch(templateChoicePinProvider);
    final Failure? failure = this.failure;
    if (failure != null) {
      return AppErrorState(failure: failure);
    }
    if (options.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.category,
        headline: localCopy.templateChoiceEmptyHeadline,
        message: localCopy.templateChoiceEmptyMessage,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.x3,
        Space.x0,
        Space.x3,
        Space.x3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final String option in options.take(_offered))
            AppListTile(
              key: ValueKey<String>('template-choice-$option'),
              title: option,
              onTap: () => onChosen?.call(option, pin),
            ),
          AppListTile(
            key: const ValueKey<String>('template-choice-other'),
            title: localCopy.templateChoiceOther,
            onTap: () => onChosen?.call(null, pin),
          ),
          AppSwitchTile.checkbox(
            title: localCopy.templateChoicePin,
            value: pin,
            onChanged: (bool value) =>
                ref.read(templateChoicePinProvider.notifier).choose(value),
          ),
        ],
      ),
    );
  }
}

/// How many templates the sheet offers before Something else.
const int _offered = 3;

/// Opens [TemplateChoiceSheet] through the shared, content-sized sheet.
Future<({String? template, bool pin})?> showTemplateChoice(
  BuildContext context, {
  required List<String> options,
  Failure? failure,
}) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppSheet<({String? template, bool pin})>(
    context,
    title: localCopy.templateChoiceTitle,
    contentSized: true,
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
