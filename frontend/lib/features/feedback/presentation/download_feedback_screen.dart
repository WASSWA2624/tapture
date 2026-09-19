import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
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
        context,
        controller,
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
          tile: (FeedbackEntry entry, int number) =>
              FeedbackEntryTile(entry: entry, number: number),
        );
        final Widget action = AppPrimaryAction(
          label: Copy.feedbackDownloadCount(matching.length),
          busy: view.busy,
          compact: true,
          onPressed: canDownload
              ? () => unawaited(_download(context, controller, matching))
              : null,
        );
        return _frame(
          context,
          controller,
          list,
          action: action,
          busy: view.busy,
          onSaveToFolder: canDownload
              ? () => unawaited(
                  _download(
                    context,
                    controller,
                    matching,
                    chooseLocation: true,
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _frame(
    BuildContext context,
    DownloadFeedbackController controller,
    Widget body, {
    Widget? action,
    bool busy = false,
    VoidCallback? onSaveToFolder,
  }) {
    return AppPage(
      title: Copy.feedbackDownload,
      compactBar: true,
      inset: false,
      footer: _footer(
        context,
        controller,
        action,
        busy: busy,
        onSaveToFolder: onSaveToFolder,
      ),
      leading: AppIconButton(
        icon: Icons.close,
        semanticLabel: Copy.close,
        tooltip: Copy.close,
        outlined: false,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      body: body,
    );
  }

  Widget? _footer(
    BuildContext context,
    DownloadFeedbackController controller,
    Widget? action, {
    required bool busy,
    VoidCallback? onSaveToFolder,
  }) {
    final String? destination = controller.destination;
    final bool canOpen = controller.canOpenFolder;
    final bool canChoose = controller.canChooseLocation;
    if (destination == null && !canOpen && !canChoose && action == null) {
      return null;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (destination != null)
          Text(
            Copy.feedbackDownloadsGoTo(destination),
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
        if (canOpen || canChoose)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Space.x2,
            runSpacing: Space.x0,
            children: <Widget>[
              if (canOpen)
                AppButton(
                  label: Copy.feedbackOpenFolder,
                  variant: AppButtonVariant.text,
                  onPressed: () => unawaited(_openFolder(context, controller)),
                ),
              if (canChoose)
                AppButton(
                  label: Copy.feedbackSaveToFolder,
                  variant: AppButtonVariant.text,
                  busy: busy,
                  onPressed: onSaveToFolder,
                ),
            ],
          ),
        if (action != null) ...<Widget>[
          if (destination != null || canOpen || canChoose)
            const SizedBox(height: Space.x2),
          action,
        ],
      ],
    );
  }
}

Future<void> _openFolder(
  BuildContext context,
  DownloadFeedbackController controller,
) async {
  final Result<void> result = await controller.openFolder();
  if (!context.mounted) {
    return;
  }
  switch (result) {
    case Success<void>():
      break;
    case FailureResult<void>(:final Failure failure):
      showAppSnack(context, failure.message, tone: SnackTone.warning);
  }
}

Future<void> _download(
  BuildContext context,
  DownloadFeedbackController controller,
  List<FeedbackEntry> matching, {
  bool chooseLocation = false,
}) async {
  final Result<String?> result = await controller.download(
    matching,
    chooseLocation: chooseLocation,
  );
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
