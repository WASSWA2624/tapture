import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import '../data/cloud_backends.dart';
import '../data/destination_repository_impl.dart';
import '../domain/upload_runner.dart';
import 'upload_confirm_sheet.dart';

/// Upload attempts, newest first, with retry on failed and interrupted rows.
final class UploadHistoryScreen extends StatelessWidget {
  /// Creates the history. A null [attempts] list is the loading state.
  const UploadHistoryScreen({
    this.attempts = const <UploadAttempt>[],
    this.loading = false,
    this.failure,
    this.destinationFilter,
    this.onRetry,
    this.live = false,
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

  /// When true, the list is the stored history and retry confirms first.
  final bool live;

  @override
  Widget build(BuildContext context) {
    if (live) {
      return const _LiveUploadHistory();
    }
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

/// Stored attempts. Retry asks for confirmation before any byte is sent.
final class _LiveUploadHistory extends ConsumerWidget {
  /// Creates the stored history.
  const _LiveUploadHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<UploadAttempt>> async = ref.watch(
      _uploadAttemptsProvider,
    );
    return async.when(
      loading: () =>
          const AppPage(title: Copy.uploadHistoryTitle, body: AppSkeleton()),
      error: (Object error, StackTrace _) => AppPage(
        title: Copy.uploadHistoryTitle,
        body: AppErrorState(
          failure: error is Failure
              ? error
              : const StorageFailure(
                  message: 'The uploads could not be read.',
                  recoveryAction: 'Try again.',
                ),
        ),
      ),
      data: (List<UploadAttempt> rows) {
        return UploadHistoryScreen(
          attempts: rows,
          onRetry: (String id) => unawaited(_retry(context, ref, rows, id)),
        );
      },
    );
  }
}

Future<void> _retry(
  BuildContext context,
  WidgetRef ref,
  List<UploadAttempt> rows,
  String id,
) async {
  UploadAttempt? attempt;
  for (final UploadAttempt row in rows) {
    if (row.id == id) {
      attempt = row;
      break;
    }
  }
  if (attempt == null) {
    return;
  }
  final bool confirmed = await confirmUpload(
    context,
    name: attempt.remoteName,
    size: Copy.fileSize(attempt.byteSize),
    destination: attempt.destinationLabel,
    folder: attempt.folder,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  final DestinationRepositoryImpl repository = ref.read(
    destinationRepositoryProvider,
  );
  final List<Destination> destinations = await repository.watchAll().first;
  Destination? destination;
  for (final Destination row in destinations) {
    if (row.id == attempt.destinationId) {
      destination = row;
      break;
    }
  }
  if (destination == null) {
    return;
  }
  final Map<DestinationKind, CloudDestination> backends =
      await openCloudBackends(repository.secrets);
  final UploadRunner runner = UploadRunner(
    destinationFor: (DestinationKind kind) {
      final Result<CloudDestination> resolved = resolveDestination(
        kind,
        backends,
      );
      if (resolved is FailureResult<CloudDestination>) {
        throw resolved.failure;
      }
      return (resolved as Success<CloudDestination>).value;
    },
    history: repository.history,
    clock: repository.clock,
  );
  await runner.retry(
    attemptId: attempt.id,
    confirmed: true,
    file: runner.openFile(attempt.filePath, attempt.byteSize),
    to: destination,
  );
}

final FutureProvider<List<UploadAttempt>> _uploadAttemptsProvider =
    FutureProvider<List<UploadAttempt>>((Ref ref) async {
      final Result<List<UploadAttempt>> result = await ref
          .watch(destinationRepositoryProvider)
          .attempts();
      return result.fold((Failure failure) => throw failure, (
        List<UploadAttempt> rows,
      ) {
        return rows;
      });
    });
