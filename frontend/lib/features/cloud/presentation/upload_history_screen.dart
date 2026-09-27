import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/cloud/domain/upload_runner.dart';

/// Upload attempts, newest first, with retry on failed and interrupted rows.
final class UploadHistoryScreen extends StatelessWidget {
  /// Creates the history. A null [attempts] list is the loading state.
  const UploadHistoryScreen({
    this.attempts = const <UploadAttempt>[],
    this.loading = false,
    this.failure,
    this.destinationFilter,
    this.onRetry,
    super.key,
  });

  /// Attempts. The screen sorts them newest first.
  final List<UploadAttempt>? attempts;

  /// Whether history is still loading.
  final bool loading;

  /// Why history could not be read.
  final Failure? failure;

  /// When set, only this destination is listed.
  final String? destinationFilter;

  /// Retries one failed or interrupted attempt. The caller must confirm again.
  final ValueChanged<String>? onRetry;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: Copy.uploadHistoryTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (loading || attempts == null) {
      return const AppPage(title: Copy.uploadHistoryTitle, body: AppSkeleton());
    }
    final List<UploadAttempt> rows =
        <UploadAttempt>[
          for (final UploadAttempt attempt in attempts!)
            if (destinationFilter == null ||
                destinationFilter!.isEmpty ||
                attempt.destinationId == destinationFilter)
              attempt,
        ]..sort(
          (UploadAttempt a, UploadAttempt b) =>
              b.startedAt.compareTo(a.startedAt),
        );
    if (rows.isEmpty) {
      return const AppPage(
        title: Copy.uploadHistoryTitle,
        body: AppEmptyState(
          icon: AppIcons.export,
          headline: Copy.uploadHistoryEmptyHeadline,
          message: Copy.uploadHistoryEmptyMessage,
        ),
      );
    }
    return AppPage(
      title: Copy.uploadHistoryTitle,
      body: Column(
        children: <Widget>[
          for (final UploadAttempt attempt in rows)
            AppListTile(
              key: ValueKey<String>('upload-${attempt.id}'),
              title: attempt.remoteName,
              subtitle: _subtitle(attempt),
              trailing: _retryable(attempt.outcome)
                  ? AppButton(
                      key: ValueKey<String>('upload-retry-${attempt.id}'),
                      label: Copy.uploadRetry,
                      onPressed: () => onRetry?.call(attempt.id),
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  bool _retryable(String outcome) {
    return outcome == 'failed' || outcome == 'interrupted';
  }

  String _subtitle(UploadAttempt attempt) {
    final String reason = attempt.failureReason ?? attempt.outcome;
    return '${attempt.destinationLabel} · ${attempt.byteSize} bytes · $reason';
  }
}
