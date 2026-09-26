import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/template_choice_needed.dart';
import '../processing.dart';
import 'egress_preview_dialog.dart';
import 'process_actions.dart';
import 'processing_batch_state.dart';
import 'processing_controller.dart';
import 'queue_providers.dart';
import 'queue_selection.dart';
import 'template_choice_sheet.dart';

/// The queue: counts from queries, grouped by context.
///
/// Tapping a group processes it; a long press selects groups for Process
/// selected. The rows are built as they scroll into view (FE-PERF-03).
class QueueScreen extends ConsumerStatefulWidget {
  /// Creates the queue. [projectId] limits the groups when set.
  const QueueScreen({super.key, this.projectId});

  /// When set, only this project's queue is shown.
  final String? projectId;

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  @override
  Widget build(BuildContext context) {
    final Set<String> picked = ref.watch(queueSelectionProvider);
    final String? projectId = widget.projectId;
    final AsyncValue<QueueSnapshot> value = projectId == null
        ? ref.watch(queueSnapshotProvider)
        : ref.watch(queueSnapshotForProjectProvider(projectId));
    final ProcessingBatchState batch = ref.watch(processingControllerProvider);
    return AppPage(
      key: const ValueKey<String>('route-queue'),
      title: Copy.queueTitle,
      scrollable: false,
      body: AsyncValueView<QueueSnapshot>(
        value: value,
        onRetry: () => projectId == null
            ? ref.invalidate(queueSnapshotProvider)
            : ref.invalidate(queueSnapshotForProjectProvider(projectId)),
        isEmpty: (QueueSnapshot snapshot) =>
            snapshot.unprocessed == 0 &&
            snapshot.queued == 0 &&
            snapshot.failed == 0 &&
            snapshot.groups.isEmpty,
        empty: () {
          return const AppEmptyState(
            icon: AppIcons.empty,
            headline: Copy.queueEmptyHeadline,
            message: Copy.queueEmptyMessage,
          );
        },
        data: (QueueSnapshot snapshot) {
          final Set<String> labels = <String>{
            for (final QueueGroup group in snapshot.groups) group.label,
          };
          // A group that has emptied out cannot stay selected.
          final Set<String> selected = picked.intersection(labels);
          final List<_QueueRow> rows = <_QueueRow>[
            if (snapshot.failures.isNotEmpty)
              const _QueueRow.header(Copy.queueFailedTitle),
            for (final ProcessingJob job in snapshot.failures)
              _QueueRow.failure(job),
            if (snapshot.groups.isNotEmpty)
              const _QueueRow.header(Copy.queueGroupsTitle),
            for (final QueueGroup group in snapshot.groups)
              _QueueRow.group(group),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                spacing: Space.x2,
                runSpacing: Space.x2,
                children: <Widget>[
                  AppStatusPill(
                    status: RecordStatus.captured,
                    label: Copy.queueUnprocessedCount(snapshot.unprocessed),
                  ),
                  AppStatusPill(
                    status: RecordStatus.queued,
                    label: Copy.queueQueuedCount(snapshot.queued),
                  ),
                  AppStatusPill(
                    status: RecordStatus.failed,
                    label: Copy.queueFailedCount(snapshot.failed),
                  ),
                ],
              ),
              const SizedBox(height: Space.x2),
              Text(
                Copy.queueUsage(
                  snapshot.requestsToday,
                  snapshot.imagesToday,
                  snapshot.requestCap,
                ),
              ),
              ProcessActions(
                steps: batch.steps,
                running: batch.isRunning,
                succeeded: batch.succeeded,
                failed: batch.failed,
                selectedCount: selected.length,
                onProcessAll: snapshot.queued == 0 && snapshot.unprocessed == 0
                    ? null
                    : () => _process(const <String>[]),
                onProcessSelected: selected.isEmpty
                    ? null
                    : () => _process(selected.toList(growable: false)),
                onCancel: batch.isRunning
                    ? ref.read(processingControllerProvider.notifier).cancel
                    : null,
              ),
              Expanded(
                child: ListView.builder(
                  key: const ValueKey<String>('queue-rows'),
                  itemCount: rows.length,
                  itemBuilder: (BuildContext _, int index) {
                    return _row(
                      rows[index],
                      running: batch.isRunning,
                      selected: selected,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(
    _QueueRow row, {
    required bool running,
    required Set<String> selected,
  }) {
    final ProcessingJob? job = row.job;
    final QueueGroup? group = row.group;
    if (job != null) {
      return AppListTile(
        leading: const Icon(AppIcons.error),
        title: '${Copy.queueRetry}: ${job.recordId}',
        subtitle: job.lastError ?? Copy.queueFailed,
        onTap: running
            ? null
            : () =>
                  ref.read(processingControllerProvider.notifier).retry(job.id),
      );
    }
    if (group != null) {
      return AppListTile(
        key: ValueKey<String>('queue-group-${group.label}'),
        leading: const Icon(AppIcons.project),
        title: group.label,
        subtitle: Copy.recordsCount(group.records),
        selected: selected.contains(group.label),
        onTap: running ? null : () => _process(<String>[group.label]),
        onLongPress: running
            ? null
            : () =>
                  ref.read(queueSelectionProvider.notifier).toggle(group.label),
      );
    }
    return AppSectionHeader(title: row.header ?? '');
  }

  /// Runs the queue for [groupLabels], every group when empty.
  void _process(List<String> groupLabels) {
    ref.read(queueSelectionProvider.notifier).clear();
    ref
        .read(processingControllerProvider.notifier)
        .process(
          projectId: widget.projectId,
          groupLabels: groupLabels,
          chooseTemplate: (TemplateChoiceNeeded needed) =>
              _chooseTemplate(context, needed),
          confirmOnline: _confirmOnline,
        );
  }

  /// The egress preview before the session's first online call. A job with
  /// nothing to send goes ahead without asking.
  Future<bool> _confirmOnline(ProcessingJob job) async {
    final ({int imageCount, int payloadBytes}) summary = await ref.read(
      processingEgressSummaryProvider,
    )(job);
    if (summary.imageCount == 0 && summary.payloadBytes == 0) {
      return true;
    }
    if (!mounted) {
      return false;
    }
    return showEgressPreview(
      context,
      imageCount: summary.imageCount,
      payloadBytes: summary.payloadBytes,
    );
  }
}

/// One row of the queue list: a section header, a failed job or a group.
final class _QueueRow {
  const _QueueRow.header(String this.header) : job = null, group = null;

  const _QueueRow.failure(ProcessingJob this.job) : header = null, group = null;

  const _QueueRow.group(QueueGroup this.group) : header = null, job = null;

  final String? header;
  final ProcessingJob? job;
  final QueueGroup? group;
}

/// Asks the operator to pick from [needed]'s shortlist and maps the chosen
/// label back to its template id. "Something else" or a dismissed sheet is
/// no answer.
Future<TemplateChoice?> _chooseTemplate(
  BuildContext context,
  TemplateChoiceNeeded needed,
) async {
  if (!context.mounted) {
    return null;
  }
  final ({String? template, bool pin})? picked = await showTemplateChoice(
    context,
    options: <String>[
      for (final ({String templateId, String label}) option in needed.shortlist)
        option.label,
    ],
  );
  final String? label = picked?.template;
  if (picked == null || label == null) {
    return null;
  }
  for (final ({String templateId, String label}) option in needed.shortlist) {
    if (option.label == label) {
      return (templateId: option.templateId, pin: picked.pin);
    }
  }
  return null;
}
