import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/feedback_entry.dart';
import '../domain/removed_feedback.dart';
import 'delete_feedback_controller.dart';
import 'delete_feedback_view.dart';
import 'feedback_entry_tile.dart';
import 'feedback_filter_panel.dart';
import 'feedback_providers.dart';

/// Filters stored feedback and deletes the entries the operator ticks.
class DeleteFeedbackScreen extends ConsumerWidget {
  /// Creates the full-screen flow.
  const DeleteFeedbackScreen({super.key, this.showAppBar = true});

  /// Creates the flow for a panel, without a second title.
  const DeleteFeedbackScreen.embedded({super.key}) : showAppBar = false;

  /// When false, the panel already shows the title.
  final bool showAppBar;

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
        const AppEmptyState(
          icon: Icons.feedback_outlined,
          headline: Copy.feedbackEmptyHeadline,
          message: Copy.feedbackEmptyMessage,
        ),
      ),
      data: (List<FeedbackEntry> all) {
        final List<FeedbackEntry> matching = view.filter.apply(all);
        final List<FeedbackEntry> page = matching.take(view.visible).toList();
        final Set<String> matchingIds = <String>{
          for (final FeedbackEntry entry in matching) entry.id,
        };
        final Set<String> selected = view.selected.intersection(matchingIds);
        final Widget list = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FeedbackFilterPanel(
              filter: view.filter,
              entries: all,
              clock: clock,
              onChanged: controller.setFilter,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.x4,
                vertical: Space.x2,
              ),
              child: Text(
                '${Copy.feedbackMatching(matching.length, all.length)} · '
                '${Copy.feedbackSelected(selected.length)}',
                style: AppText.caption.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ),
            if (view.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x4),
                child: Text(
                  view.error!,
                  style: AppText.body.copyWith(color: context.colors.onSurface),
                ),
              ),
            if (matching.isEmpty)
              const AppEmptyState(
                icon: Icons.filter_alt_outlined,
                headline: Copy.feedbackNoMatchHeadline,
                message: Copy.feedbackNoMatchMessage,
              )
            else ...<Widget>[
              AppButton(
                label: Copy.selectAll,
                variant: AppButtonVariant.text,
                onPressed: () => controller.toggleAll(matchingIds),
              ),
              for (final FeedbackEntry entry in page)
                FeedbackEntryTile(
                  entry: entry,
                  selected: selected.contains(entry.id),
                  onTap: () => controller.toggle(entry.id),
                  onLongPress: () => controller.toggle(entry.id),
                ),
              if (page.length < matching.length)
                AppButton(
                  label: Copy.feedbackShowMore,
                  variant: AppButtonVariant.text,
                  onPressed: controller.showMore,
                ),
            ],
          ],
        );
        final Widget action = AppPrimaryAction(
          label: Copy.feedbackDeleteCount(selected.length),
          busy: view.busy,
          onPressed: selected.isEmpty
              ? null
              : () => unawaited(_delete(context, controller, selected.length)),
        );
        return _frame(list, footer: action);
      },
    );
  }

  Widget _frame(Widget body, {Widget? footer}) {
    if (!showAppBar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: SingleChildScrollView(child: body)),
          if (footer != null)
            Padding(padding: const EdgeInsets.all(Space.x4), child: footer),
        ],
      );
    }
    return AppPage(
      title: Copy.feedbackDelete,
      inset: false,
      footer: footer,
      body: body,
    );
  }
}

Future<void> _delete(
  BuildContext context,
  DeleteFeedbackController controller,
  int count,
) async {
  final bool confirmed = await showAppConfirm(
    context,
    title: Copy.feedbackDeleteTitle(count),
    message: Copy.feedbackDeleteMessage(count),
    confirmLabel: Copy.feedbackDeleteCount(count),
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
        Copy.feedbackDeleted(value.length),
        tone: SnackTone.success,
        undoLabel: Copy.undo,
        onUndo: () => unawaited(controller.restore(value)),
      );
    case FailureResult<List<RemovedFeedback>>():
      break;
  }
}
