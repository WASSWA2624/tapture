import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/feedback_entry.dart';
import 'download_feedback_controller.dart';
import 'download_feedback_view.dart';
import 'feedback_browser.dart';
import 'feedback_entry_tile.dart';
import 'feedback_providers.dart';

/// Filters stored feedback and downloads a zip of the workbook and matching
/// screenshots.
class DownloadFeedbackScreen extends ConsumerWidget {
  /// Creates the full-screen flow.
  const DownloadFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DownloadFeedbackView view = ref.watch(
      downloadFeedbackControllerProvider,
    );
    final DownloadFeedbackController controller = ref.read(
      downloadFeedbackControllerProvider.notifier,
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
        final bool canDownload =
            matching.isNotEmpty && !view.filter.isRangeBackwards;
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
          tile: (FeedbackEntry entry) => FeedbackEntryTile(entry: entry),
        );
        final Widget action = AppPrimaryAction(
          label: Copy.feedbackDownloadCount(matching.length),
          busy: view.busy,
          compact: true,
          onPressed: canDownload
              ? () => unawaited(_download(context, controller, matching))
              : null,
        );
        return _frame(list, footer: action);
      },
    );
  }

  Widget _frame(Widget body, {Widget? footer}) {
    return AppPage(
      title: Copy.feedbackDownload,
      compactBar: true,
      inset: false,
      footer: footer,
      body: body,
    );
  }
}

Future<void> _download(
  BuildContext context,
  DownloadFeedbackController controller,
  List<FeedbackEntry> matching,
) async {
  final Result<String?> result = await controller.download(matching);
  if (!context.mounted) {
    return;
  }
  switch (result) {
    case Success<String?>(:final String? value):
      showAppSnack(
        context,
        value == null
            ? Copy.feedbackDownloadStarted
            : Copy.feedbackDownloadedTo(value),
        tone: SnackTone.success,
      );
      Navigator.of(context).pop(true);
    case FailureResult<String?>():
      break;
  }
}
