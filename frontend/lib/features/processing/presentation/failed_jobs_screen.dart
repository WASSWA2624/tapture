import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import '../processing.dart';
import 'queue_providers.dart';

/// Failed jobs, each with the reason the classifier stored, and one retry.
class FailedJobsScreen extends ConsumerWidget {
  /// Creates the list.
  const FailedJobsScreen({super.key, this.onRetry});

  /// Retries [jobId].
  final Future<void> Function(String jobId)? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<QueueSnapshot> value = ref.watch(queueSnapshotProvider);
    return AppPage(
      title: Copy.queueFailedTitle,
      scrollable: false,
      body: AsyncValueView<QueueSnapshot>(
        value: value,
        onRetry: () => ref.invalidate(queueSnapshotProvider),
        isEmpty: (QueueSnapshot snapshot) => snapshot.failures.isEmpty,
        empty: () {
          return const AppEmptyState(
            icon: Icons.task_alt,
            headline: Copy.queueFailedEmptyHeadline,
            message: Copy.queueFailedEmptyMessage,
          );
        },
        data: (QueueSnapshot snapshot) {
          return ListView.builder(
            itemCount: snapshot.failures.length,
            itemBuilder: (BuildContext context, int index) {
              final ProcessingJob job = snapshot.failures[index];
              final String reason = job.lastError ?? Copy.queueFailed;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppErrorState(
                    failure: ProviderFailure(
                      message: reason,
                      recoveryAction: Copy.queueRetry,
                    ),
                    onRetry: () => onRetry?.call(job.id),
                  ),
                  AppButton(
                    label: Copy.queueRetry,
                    onPressed: () => onRetry?.call(job.id),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
