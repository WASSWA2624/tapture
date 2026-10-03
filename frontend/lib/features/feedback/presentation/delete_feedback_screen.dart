import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/feedback_entry.dart';
import '../domain/removed_feedback.dart';
import 'delete_feedback_controller.dart';
import 'delete_feedback_view.dart';
import 'feedback_browser.dart';
import 'feedback_entry_tile.dart';
import 'feedback_providers.dart';

/// Filters stored feedback and deletes the entries the operator ticks.
class DeleteFeedbackScreen extends ConsumerWidget {
  /// Creates the full-screen flow.
  const DeleteFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeleteFeedbackView view = ref.watch(deleteFeedbackControllerProvider);
    final DeleteFeedbackController controller = ref.read(
      deleteFeedbackControllerProvider.notifier,
    );
    final Clock clock = ref.watch(feedbackClockProvider);
    final AsyncValue<List<FeedbackEntry>> entries = ref.watch(
      feedbackEntriesProvider,
    );
    return AsyncValueView<List<FeedbackEntry>>(
      value: entries,
      onRetry: () => ref.invalidate(feedbackEntriesProvider),
      isEmpty: (List<FeedbackEntry> all) => all.isEmpty,
      empty: () => _frame(
        context,
        AppEmptyState(
          icon: AppIcons.feedback,
          headline: Copy.of(context).feedbackEmptyHeadline,
          message: Copy.of(context).feedbackEmptyMessage,
        ),
      ),
      data: (List<FeedbackEntry> all) {
        final LocalizedCopy localCopy = Copy.of(context);

        final List<FeedbackEntry> matching = view.filter.apply(all);
        final Set<String> matchingIds = <String>{
          for (final FeedbackEntry entry in matching) entry.id,
        };
        final Set<String> selected = view.selected.intersection(matchingIds);
        final Widget list = FeedbackBrowser(
          all: all,
          matching: matching,
          visible: view.visible,
          filter: view.filter,
          clock: clock,
          moreFilters: view.moreFilters,
          onFilter: controller.setFilter,
          onToggleMoreFilters: controller.toggleMoreFilters,
          onShowMore: controller.showMore,
          error: view.error,
          localizedError: view.localizedError,
          lead: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4),
            child: AppSwitchTile.checkbox(
              key: const ValueKey<String>('feedback-select-all'),
              title: localCopy.selectAll,
              value: selected.length == matchingIds.length,
              dense: true,
              controlFirst: true,
              divided: false,
              onChanged: (bool _) => controller.toggleAll(matchingIds),
            ),
          ),
          tile: (FeedbackEntry entry, int number) => FeedbackEntryTile(
            entry: entry,
            number: number,
            selected: selected.contains(entry.id),
            onTap: () => controller.toggle(entry.id),
            onLongPress: () => controller.toggle(entry.id),
          ),
        );
        final Widget action = AppPrimaryAction(
          label: localCopy.feedbackDeleteCount(selected.length),
          busy: view.busy,
          compact: true,
          onPressed: selected.isEmpty
              ? null
              : () => unawaited(_delete(context, controller, selected.length)),
        );
        return _frame(context, list, footer: action);
      },
    );
  }

  Widget _frame(BuildContext context, Widget body, {Widget? footer}) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppPage(
      title: localCopy.feedbackDelete,
      compactBar: true,
      inset: false,
      footer: footer,
      leading: AppIconButton(
        icon: AppIcons.close,
        semanticLabel: localCopy.close,
        tooltip: localCopy.close,
        outlined: false,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      body: body,
    );
  }
}

Future<void> _delete(
  BuildContext context,
  DeleteFeedbackController controller,
  int count,
) async {
  final LocalizedCopy localCopy = Copy.of(context);

  final bool confirmed = await showAppConfirm(
    context,
    title: localCopy.feedbackDeleteTitle(count),
    message: localCopy.feedbackDeleteMessage(count),
    confirmLabel: localCopy.feedbackDeleteCount(count),
    destructive: true,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  final Result<List<RemovedFeedback>> result = await controller
      .removeSelected();
  if (!context.mounted) {
    return;
  }
  switch (result) {
    case Success<List<RemovedFeedback>>(:final List<RemovedFeedback> value):
      showAppSnack(
        context,
        localCopy.feedbackDeleted(value.length),
        tone: SnackTone.success,
        undoLabel: localCopy.undo,
        onUndo: () => unawaited(controller.restore(value)),
      );
    case FailureResult<List<RemovedFeedback>>():
      break;
  }
}
