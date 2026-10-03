import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../exports.dart';
import 'export_share_action.dart';
import 'export_workflow.dart';
import 'export_workflow_controller.dart';

final _historyProvider = StreamProvider.autoDispose
    .family<List<DeliverableEntry>, String>((Ref ref, String projectId) {
      final DeliverableRepository? store = ref.watch(
        deliverableRepositoryProvider,
      );
      return store?.watchHistory(projectId: projectId) ??
          Stream<List<DeliverableEntry>>.error(_unavailable);
    }, retry: (int _, Object _) => null);

class ExportWorkflowHistory extends ConsumerWidget {
  const ExportWorkflowHistory({
    required this.projectId,
    this.recordCount,
    super.key,
  });

  final String projectId;
  final int? recordCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView<List<DeliverableEntry>>(
      value: ref.watch(_historyProvider(projectId)),
      isEmpty: (List<DeliverableEntry> entries) => entries.isEmpty,
      onRetry: () => ref.invalidate(_historyProvider(projectId)),
      empty: () => AppEmptyState(
        icon: AppIcons.history,
        headline: Copy.of(context).exportHistoryEmpty,
        message: recordCount == 0
            ? Copy.of(context).recordsEmptyMessage
            : Copy.of(context).exportHistoryEmptyMessage,
        actionLabel: recordCount == 0
            ? Copy.of(context).recordsEmptyAction
            : Copy.of(context).navRecords,
        onAction: () => context.go(
          recordCount == 0
              ? RoutePaths.projectCapture(projectId)
              : RoutePaths.projectRecords(projectId),
        ),
      ),
      data: (List<DeliverableEntry> entries) => Column(
        children: <Widget>[
          for (final DeliverableEntry entry in entries) ...<Widget>[
            AppListTile(
              key: ValueKey<String>('export-history-${entry.id}'),
              title: entry.fileName,
              subtitle: Copy.of(context).exportHistoryDetail(
                DateFormat.yMd().add_jm().format(entry.createdAt.toLocal()),
                entry.operatorName,
                entry.recordCount,
              ),
              onTap: () => unawaited(shareDeliverable(context, ref, entry)),
            ),
            ExportShareAction(
              path: entry.path,
              missing: entry.missing,
              onShare: (_) => unawaited(shareDeliverable(context, ref, entry)),
              onRerun: () => unawaited(_rerun(context, ref, entry)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _rerun(
    BuildContext context,
    WidgetRef ref,
    DeliverableEntry entry,
  ) async {
    final ExportWorkflowController controller = ref.read(
      exportWorkflowControllerProvider(projectId).notifier,
    );
    if (entry.package) {
      // The package writer always takes the whole current project.
      final ExportWorkflow? current = ref
          .read(exportWorkflowControllerProvider(projectId))
          .value;
      if (current != null) {
        await controller.run(
          replay: current.request.copyWith(
            formats: const <ExportFormat>{ExportFormat.zip},
          ),
          decide: (_) async => null,
        );
      }
      return;
    }
    final DeliverableRepository? store = ref.read(
      deliverableRepositoryProvider,
    );
    if (store == null) return;
    final Result<ExportRequest> replay = await store.replay(entry.id);
    if (!context.mounted) return;
    switch (replay) {
      case Success<ExportRequest>(:final ExportRequest value):
        await controller.run(replay: value, decide: (_) async => null);
      case FailureResult<ExportRequest>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
    }
  }
}

Future<void> shareDeliverable(
  BuildContext context,
  WidgetRef ref,
  DeliverableEntry entry,
) async {
  final DeliverableRepository? store = ref.read(deliverableRepositoryProvider);
  if (store case final ExportSharingPolicy policy) {
    final Result<void> allowed = await policy.allowShare(entry.id);
    if (!context.mounted) return;
    if (allowed case FailureResult<void>(:final Failure failure)) {
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
      return;
    }
  }
  final Result<void> result = await ref
      .read(downloadServiceProvider)
      .openStoredExternally(
        relativePath: entry.path,
        fileName: entry.fileName,
        mimeType: entry.mimeType,
      );
  if (!context.mounted) return;
  if (result case FailureResult<void>(
    :final Failure failure,
  ) when failure is! CancelledFailure) {
    showAppSnack(
      context,
      failure.message,
      tone: SnackTone.error,
      localizedMessage: failure.explanation,
    );
  }
}

final StorageFailure _unavailable = StorageFailure(
  localizedMessage: Copy.messages.failureProjectFilesAreUnavailableOnThisDevice,
);
