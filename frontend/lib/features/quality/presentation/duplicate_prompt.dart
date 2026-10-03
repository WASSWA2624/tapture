import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/duplicate_choice.dart';
import '../domain/duplicate_pair_view.dart';
import 'duplicate_choice_controller.dart';
import 'quality_providers.dart';

/// The one question a duplicate asks (task 015): the values that differ, the
/// four outcomes, and one action that goes on with the chosen one.
///
/// Dismissing the sheet chooses nothing: both records and the pair stay
/// unresolved. Choosing to update the existing record leads to the
/// comparison, the only place an override happens.
final class DuplicatePrompt extends ConsumerWidget {
  /// Creates the prompt for pair [pairId].
  const DuplicatePrompt({
    required this.pairId,
    required this.onChoose,
    super.key,
  });

  /// The pair asked about.
  final String pairId;

  /// Called with the outcome a person chose.
  final ValueChanged<DuplicateChoice> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView<DuplicatePairView?>(
      value: ref.watch(duplicatePairProvider(pairId)),
      onRetry: () => ref.invalidate(duplicatePairProvider(pairId)),
      isEmpty: (DuplicatePairView? pair) => pair == null,
      empty: () => AppEmptyState(
        icon: AppIcons.duplicate,
        headline: Copy.of(context).duplicatesEmptyHeadline,
        message: Copy.of(context).duplicatePairGone,
        actionLabel: Copy.of(context).close,
        onAction: () => Navigator.of(context).maybePop(),
      ),
      data: (DuplicatePairView? pair) => _question(context, ref, pair!),
    );
  }

  Widget _question(
    BuildContext context,
    WidgetRef ref,
    DuplicatePairView pair,
  ) {
    final String question = 'prompt:$pairId';
    // Keeping both is offered first and changes nothing irreversible.
    final DuplicateChoice choice =
        ref.watch(duplicateChoiceControllerProvider(question)) ??
        DuplicateChoice.keepBoth;
    return Padding(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (pair.differences.isEmpty)
            AppBanner(
              message: Copy.of(context).duplicateNoDifferenceMessage,
              icon: AppIcons.info,
              tone: SnackTone.info,
            )
          else
            for (final DuplicateDifference row in pair.differences)
              AppListTile(
                key: ValueKey<String>('duplicate-difference-${row.fieldKey}'),
                dense: true,
                title: row.label,
                subtitle: Copy.of(
                  context,
                ).duplicateValueChange(row.existing, row.incoming),
              ),
          const SizedBox(height: Space.x3),
          AppRadioGroup<DuplicateChoice>(
            key: const ValueKey<String>('duplicate-choice'),
            label: Copy.of(context).duplicatePromptQuestion,
            value: choice,
            options: <Choice<DuplicateChoice>>[
              Choice<DuplicateChoice>(
                DuplicateChoice.keepBoth,
                Copy.of(context).duplicateLinkBoth,
              ),
              Choice<DuplicateChoice>(
                DuplicateChoice.mergeFields,
                Copy.of(context).duplicateMerge,
              ),
              Choice<DuplicateChoice>(
                DuplicateChoice.overrideExisting,
                Copy.of(context).duplicateCompareThenUpdate,
              ),
              Choice<DuplicateChoice>(
                DuplicateChoice.discardNew,
                Copy.of(context).duplicateDiscard,
              ),
            ],
            onChanged: (DuplicateChoice next) => ref
                .read(duplicateChoiceControllerProvider(question).notifier)
                .pick(next),
          ),
          const SizedBox(height: Space.x4),
          AppPrimaryAction(
            key: const ValueKey<String>('duplicate-continue'),
            label: Copy.of(context).duplicatePromptContinue,
            onPressed: () => onChoose(choice),
          ),
        ],
      ),
    );
  }
}

/// Opens the prompt for pair [pairId]. Returns the chosen outcome, or null
/// when the sheet is dismissed, which leaves the pair unresolved.
Future<DuplicateChoice?> showDuplicatePrompt(
  BuildContext context,
  String pairId,
) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppSheet<DuplicateChoice>(
    context,
    title: localCopy.duplicatePromptTitle,
    contentSized: true,
    builder: (BuildContext sheet) {
      return DuplicatePrompt(
        pairId: pairId,
        onChoose: (DuplicateChoice choice) => Navigator.of(sheet).pop(choice),
      );
    },
  );
}
