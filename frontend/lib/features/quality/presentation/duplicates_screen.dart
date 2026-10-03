import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/duplicate_choice.dart';
import '../domain/duplicate_pair_view.dart';
import '../domain/duplicate_resolution.dart';
import 'duplicate_choice_controller.dart';
import 'duplicate_flow.dart';
import 'duplicates_controller.dart';
import 'quality_providers.dart';

/// A project's unresolved duplicate pairs, grouped by the signal and
/// template that produced them, cleared in place (task 015).
///
/// Each row carries the fields that differ, so most pairs need no other
/// screen. A group can be cleared at once, but only after the person picks
/// the outcome and confirms it with the number of records it changes.
final class DuplicatesScreen extends ConsumerWidget {
  /// Creates the review list for [projectId].
  const DuplicatesScreen({required this.projectId, super.key});

  /// The project whose pairs are listed.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool busy = ref.watch(duplicatesControllerProvider);
    return AppPage(
      key: const ValueKey<String>('route-duplicates'),
      title: localCopy.duplicatesTitle,
      inset: false,
      overflow: <AppOverflowAction>[
        AppOverflowAction(
          key: const ValueKey<String>('duplicates-scan'),
          label: localCopy.duplicatesScan,
          icon: AppIcons.search,
          onTap: () => unawaited(_scan(context, ref)),
        ),
      ],
      body: AsyncValueView<List<DuplicatePairView>>(
        value: ref.watch(duplicatePairsProvider(projectId)),
        onRetry: () => ref.invalidate(duplicatePairsProvider(projectId)),
        isEmpty: (List<DuplicatePairView> pairs) => pairs.isEmpty,
        empty: () => AppEmptyState(
          icon: AppIcons.duplicate,
          headline: Copy.of(context).duplicatesEmptyHeadline,
          message: Copy.of(context).duplicatesEmptyMessage,
          actionLabel: Copy.of(context).duplicatesScan,
          onAction: () => unawaited(_scan(context, ref)),
        ),
        data: (List<DuplicatePairView> pairs) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final MapEntry<String, List<DuplicatePairView>> group
                in _groups(pairs).entries) ...<Widget>[
              AppSectionHeader(
                title: _groupLabel(
                  group.value.first,
                  localizedCopy: Copy.of(context),
                ),
              ),
              for (final DuplicatePairView pair in group.value)
                AppListTile(
                  key: ValueKey<String>('duplicate-pair-${pair.id}'),
                  title: Copy.of(context).duplicatePairTitle(
                    DuplicateFlow.title(
                      pair.existing.name,
                      pair.existing.number,
                      localizedCopy: Copy.of(context),
                    ),
                    DuplicateFlow.title(
                      pair.incoming.name,
                      pair.incoming.number,
                      localizedCopy: Copy.of(context),
                    ),
                  ),
                  subtitle: pair.differences.isEmpty
                      ? Copy.of(context).duplicateNoDifferenceMessage
                      : <String>[
                          for (final DuplicateDifference row
                              in pair.differences)
                            Copy.of(context).duplicateDifferenceLine(
                              row.label,
                              row.existing,
                              row.incoming,
                            ),
                        ].join('; '),
                  trailing: const Icon(AppIcons.open),
                  onTap: () => unawaited(
                    DuplicateFlow.open(
                      context,
                      ref,
                      projectId: projectId,
                      pairId: pair.id,
                    ),
                  ),
                ),
              // One pair is cleared from its row; a choice for the whole
              // group is offered only where there is more than one.
              if (group.value.length > 1)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppPage.gutter(context),
                    vertical: Space.x2,
                  ),
                  child: AppButton(
                    key: ValueKey<String>('duplicate-group-${group.key}'),
                    label: Copy.of(context).duplicatesResolveGroup,
                    variant: AppButtonVariant.secondary,
                    onPressed: busy
                        ? null
                        : () => unawaited(
                            _resolveGroup(context, ref, group.key, group.value),
                          ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Runs detection over the whole project and says how many pairs it
  /// queued.
  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Result<int> scanned = await ref
        .read(duplicatesControllerProvider.notifier)
        .scan(projectId);
    if (!context.mounted) {
      return;
    }
    switch (scanned) {
      case Success<int>(:final int value):
        showAppSnack(context, localCopy.duplicatesScanned(value));
      case FailureResult<int>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
    }
  }

  /// Asks which outcome [pairs] get, confirms it with the number of records
  /// it changes, then applies it to each pair of this group alone.
  Future<void> _resolveGroup(
    BuildContext context,
    WidgetRef ref,
    String group,
    List<DuplicatePairView> pairs,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final DuplicateChoice? choice = await showAppSheet<DuplicateChoice>(
      context,
      title: localCopy.duplicatesBulkChoose,
      contentSized: true,
      builder: (BuildContext sheet) => _BulkChoice(
        question: 'bulk:$projectId:$group',
        onChoose: (DuplicateChoice picked) => Navigator.of(sheet).pop(picked),
      ),
    );
    if (choice == null || !context.mounted) {
      return;
    }
    final int changed = choice == DuplicateChoice.keepBoth
        ? <String>{
            for (final DuplicatePairView pair in pairs) ...<String>[
              pair.existing.recordId,
              pair.incoming.recordId,
            ],
          }.length
        : pairs.length;
    final String label = DuplicateFlow.label(
      choice,
      localizedCopy: Copy.of(context),
    );
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.duplicatesBulkTitle(changed, label),
      message: localCopy.duplicatesBulkMessage(changed),
      confirmLabel: label,
      destructive: choice == DuplicateChoice.discardNew,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final ({int resolved, Failure? failure}) outcome = await ref
        .read(duplicatesControllerProvider.notifier)
        .resolveAll(<String>[
          for (final DuplicatePairView pair in pairs) pair.id,
        ], DuplicateResolution(choice));
    if (!context.mounted) {
      return;
    }
    final Failure? failed = outcome.failure;
    showAppSnack(
      context,
      failed == null
          ? localCopy.duplicatesBulkDone(outcome.resolved)
          : failed.message,
      tone: failed == null ? SnackTone.success : SnackTone.error,
    );
  }
}

/// The outcome a whole group gets. Nothing is selected until the person
/// picks one; only outcomes that need no per-pair decision are offered.
class _BulkChoice extends ConsumerWidget {
  const _BulkChoice({required this.question, required this.onChoose});

  final String question;
  final ValueChanged<DuplicateChoice> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final DuplicateChoice? choice = ref.watch(
      duplicateChoiceControllerProvider(question),
    );
    return Padding(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppRadioGroup<DuplicateChoice>(
            key: const ValueKey<String>('duplicate-bulk-choice'),
            label: localCopy.duplicatePromptQuestion,
            value: choice,
            options: <Choice<DuplicateChoice>>[
              for (final DuplicateChoice option in DuplicateChoice.values)
                if (DuplicateResolution.bulkAllowed(option))
                  Choice<DuplicateChoice>(
                    option,
                    DuplicateFlow.label(
                      option,
                      localizedCopy: Copy.of(context),
                    ),
                  ),
            ],
            onChanged: (DuplicateChoice next) => ref
                .read(duplicateChoiceControllerProvider(question).notifier)
                .pick(next),
          ),
          const SizedBox(height: Space.x4),
          AppPrimaryAction(
            key: const ValueKey<String>('duplicate-bulk-continue'),
            label: localCopy.duplicatePromptContinue,
            onPressed: choice == null ? null : () => onChoose(choice),
          ),
        ],
      ),
    );
  }
}

/// [pairs] by signal and template, in the order they arrived.
Map<String, List<DuplicatePairView>> _groups(List<DuplicatePairView> pairs) {
  final Map<String, List<DuplicatePairView>> grouped =
      <String, List<DuplicatePairView>>{};
  for (final DuplicatePairView pair in pairs) {
    grouped
        .putIfAbsent(
          '${pair.signal.name}-${pair.templateId}',
          () => <DuplicatePairView>[],
        )
        .add(pair);
  }
  return grouped;
}

String _groupLabel(DuplicatePairView pair, {LocalizedCopy? localizedCopy}) {
  return (localizedCopy ?? Copy.english).duplicatesGroup(
    (localizedCopy ?? Copy.english).duplicateSignal(pair.signal.name),
    pair.templateName,
  );
}
