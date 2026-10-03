import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/upload_runner.dart';
import 'destination_labels.dart';
import 'upload_confirm_sheet.dart';
import 'upload_controller.dart';
import 'upload_history_controller.dart';
import 'upload_outcome.dart';

/// Upload attempts, newest first, filterable by destination, with retry on
/// failed and interrupted rows and stop on running ones (task 021 step 6).
final class UploadHistoryScreen extends ConsumerWidget {
  /// Creates the history.
  const UploadHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppPage(
      title: localCopy.uploadHistoryTitle,
      inset: false,
      body: AsyncValueView<List<UploadAttempt>>(
        value: ref.watch(uploadAttemptsProvider),
        onRetry: () => ref.invalidate(uploadAttemptsProvider),
        isEmpty: (List<UploadAttempt> attempts) => attempts.isEmpty,
        empty: () => AppEmptyState(
          icon: AppIcons.upload,
          headline: Copy.of(context).uploadHistoryEmptyHeadline,
          message: Copy.of(context).uploadHistoryEmptyMessage,
          actionLabel: Copy.of(context).uploadHistoryEmptyAction,
          onAction: () => context.go(RoutePaths.settingsDestinations),
        ),
        data: (List<UploadAttempt> attempts) => _History(attempts: attempts),
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.attempts});

  final List<UploadAttempt> attempts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? filter = ref.watch(uploadHistoryControllerProvider);
    final Map<String, UploadProgress> running = ref.watch(
      uploadControllerProvider,
    );
    final Map<String, String> destinations = <String, String>{
      for (final UploadAttempt attempt in attempts)
        attempt.destinationId: attempt.destinationLabel,
    };
    final List<UploadAttempt> shown =
        <UploadAttempt>[
          for (final UploadAttempt attempt in attempts)
            if (filter == null || attempt.destinationId == filter) attempt,
        ]..sort(
          (UploadAttempt a, UploadAttempt b) =>
              b.startedAt.compareTo(a.startedAt),
        );
    final List<MapEntry<String, String>> choices = destinations.entries.toList()
      ..sort(
        (MapEntry<String, String> a, MapEntry<String, String> b) =>
            a.value.compareTo(b.value),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (choices.length > 1)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppPage.gutter(context),
              vertical: Space.x2,
            ),
            child: AppChoiceField<String>(
              key: const ValueKey<String>('upload-filter'),
              label: localCopy.uploadFilter,
              alwaysSheet: true,
              options: <Choice<String>>[
                Choice<String>('', localCopy.uploadFilterAll),
                for (final MapEntry<String, String> choice in choices)
                  Choice<String>(choice.key, choice.value),
              ],
              value: filter ?? '',
              onChanged: ref
                  .read(uploadHistoryControllerProvider.notifier)
                  .filterBy,
            ),
          ),
        for (final UploadAttempt attempt in shown)
          _row(context, ref, attempt, running[attempt.id]),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    WidgetRef ref,
    UploadAttempt attempt,
    UploadProgress? live,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool retryable =
        live == null &&
        (attempt.outcome == 'failed' || attempt.outcome == 'interrupted');
    return AppListTile(
      key: ValueKey<String>('upload-${attempt.id}'),
      title: attempt.remoteName,
      subtitle: live == null
          ? localCopy.uploadAttemptLine(
              outcome: uploadOutcomeLabel(attempt.outcome, copy: localCopy),
              destination: attempt.destinationLabel,
              size: localCopy.fileSize(attempt.byteSize),
              startedAt: attempt.startedAt,
            )
          : localCopy.uploadSendingLine(
              destination: attempt.destinationLabel,
              percent: live.total <= 0 ? 0 : (live.sent * 100) ~/ live.total,
            ),
      leading: Icon(uploadOutcomeIcon(live?.outcome ?? attempt.outcome)),
      onTap: () => unawaited(_details(context, attempt)),
      trailing: AppOverflowMenu(
        key: ValueKey<String>('upload-actions-${attempt.id}'),
        items: <AppOverflowAction>[
          if (live != null)
            AppOverflowAction(
              key: ValueKey<String>('upload-stop-${attempt.id}'),
              label: localCopy.uploadStop,
              icon: AppIcons.stop,
              onTap: () => unawaited(
                ref.read(uploadControllerProvider.notifier).cancel(attempt.id),
              ),
            ),
          if (retryable)
            AppOverflowAction(
              key: ValueKey<String>('upload-retry-${attempt.id}'),
              label: localCopy.uploadRetry,
              icon: AppIcons.upload,
              onTap: () => unawaited(_retry(context, ref, attempt)),
            ),
          AppOverflowAction(
            key: ValueKey<String>('upload-details-${attempt.id}'),
            label: localCopy.uploadDetails,
            icon: AppIcons.info,
            onTap: () => unawaited(_details(context, attempt)),
          ),
        ],
      ),
    );
  }

  Future<void> _details(BuildContext context, UploadAttempt attempt) {
    final LocalizedCopy localCopy = Copy.of(context);

    return showAppAlert(
      context,
      title: attempt.remoteName,
      message: localCopy.uploadDetailsMessage(
        file: attempt.filePath,
        destination: attempt.destinationLabel,
        folder: destinationFolderLabel(attempt.folder, copy: localCopy),
        size: localCopy.fileSize(attempt.byteSize),
        startedAt: attempt.startedAt,
        endedAt: attempt.endedAt,
        outcome: uploadOutcomeLabel(attempt.outcome, copy: localCopy),
        reason: attempt.localizedFailure == null
            ? attempt.failureReason
            : localCopy.resolve(attempt.localizedFailure!),
      ),
    );
  }

  /// A retry asks again, through the same sheet as the first send, before
  /// any credential is read.
  Future<void> _retry(
    BuildContext context,
    WidgetRef ref,
    UploadAttempt attempt,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final UploadController uploads = ref.read(
      uploadControllerProvider.notifier,
    );
    final bool confirmed = await confirmUpload(
      context,
      name: attempt.remoteName,
      size: localCopy.fileSize(attempt.byteSize),
      destination: attempt.destinationLabel,
      folder: destinationFolderLabel(attempt.folder, copy: localCopy),
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final BuildContext host = Navigator.of(
      context,
      rootNavigator: true,
    ).context;
    final UploadProgress outcome = await uploads.retry(
      attempt,
      confirmed: confirmed,
    );
    if (host.mounted) {
      reportUpload(
        host,
        outcome,
        name: attempt.remoteName,
        destination: attempt.destinationLabel,
      );
    }
  }
}
