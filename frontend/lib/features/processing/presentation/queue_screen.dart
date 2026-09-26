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
import 'template_choice_sheet.dart';

/// The queue: counts from queries, grouped by context.
class QueueScreen extends ConsumerWidget {
  /// Creates the queue. [projectId] limits the groups when set.
  const QueueScreen({super.key, this.projectId});

  /// When set, only this project's queue is shown.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? projectId = this.projectId;
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
        onRetry: () => ref.invalidate(queueSnapshotProvider),
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
                onProcessAll: snapshot.queued == 0 && snapshot.unprocessed == 0
                    ? null
                    : () => ref
                          .read(processingControllerProvider.notifier)
                          .process(
                            projectId: projectId,
                            chooseTemplate: (TemplateChoiceNeeded needed) =>
                                _chooseTemplate(context, needed),
                            confirmOnline: (ProcessingJob job) async {
                              final summary = await ref.read(
                                processingEgressSummaryProvider,
                              )(job);
                              if (summary.imageCount == 0 &&
                                  summary.payloadBytes == 0) {
                                return true;
                              }
                              if (!context.mounted) {
                                return false;
                              }
                              return showEgressPreview(
                                context,
                                imageCount: summary.imageCount,
                                payloadBytes: summary.payloadBytes,
                              );
                            },
                          ),
                onCancel: batch.isRunning
                    ? ref.read(processingControllerProvider.notifier).cancel
                    : null,
              ),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    if (snapshot.failures.isNotEmpty)
                      const AppSectionHeader(title: Copy.queueFailedTitle),
                    for (final ProcessingJob job in snapshot.failures)
                      AppListTile(
                        leading: const Icon(AppIcons.error),
                        title: '${Copy.queueRetry}: ${job.recordId}',
                        subtitle: job.lastError ?? Copy.queueFailed,
                        onTap: batch.isRunning
                            ? null
                            : () => ref
                                  .read(processingControllerProvider.notifier)
                                  .retry(job.id),
                      ),
                    if (snapshot.groups.isNotEmpty)
                      const AppSectionHeader(title: Copy.queueGroupsTitle),
                    for (final QueueGroup group in snapshot.groups)
                      AppListTile(
                        leading: const Icon(AppIcons.project),
                        title: group.label,
                        subtitle: Copy.recordsCount(group.records),
                        onTap: batch.isRunning
                            ? null
                            : () => ref
                                  .read(processingControllerProvider.notifier)
                                  .process(
                                    projectId: projectId,
                                    groupLabel: group.label,
                                    chooseTemplate:
                                        (TemplateChoiceNeeded needed) =>
                                            _chooseTemplate(context, needed),
                                    confirmOnline: (ProcessingJob job) async {
                                      final summary = await ref.read(
                                        processingEgressSummaryProvider,
                                      )(job);
                                      if (summary.imageCount == 0 &&
                                          summary.payloadBytes == 0) {
                                        return true;
                                      }
                                      if (!context.mounted) {
                                        return false;
                                      }
                                      return showEgressPreview(
                                        context,
                                        imageCount: summary.imageCount,
                                        payloadBytes: summary.payloadBytes,
                                      );
                                    },
                                  ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
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
