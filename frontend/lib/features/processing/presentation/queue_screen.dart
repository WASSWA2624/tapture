import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/template_choice_needed.dart';
import '../processing.dart';
import 'process_actions.dart';
import 'processing_batch_state.dart';
import 'queue_providers.dart';
import 'queue_selection.dart';
import 'template_choice_sheet.dart';

/// The queue: one summary, the failed jobs, then the waiting records grouped
/// by context, with Process all as the page's one primary action.
///
/// Tapping a group picks it for Process selected; a failed row opens its
/// record and retries from its own control. Everything scrolls as one list,
/// built as it comes into view (FE-PERF-03, FE-RESP-06).
class QueueScreen extends ConsumerStatefulWidget {
  /// Creates the queue. [projectId] limits the groups when set.
  const QueueScreen({super.key, this.projectId});

  /// When set, only this project's queue is shown.
  final String? projectId;

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> with StateRefresh {
  final ScrollController _rowsController = ScrollController();
  final List<QueueFailureCursor> _failureCursors = <QueueFailureCursor>[];

  @override
  void didUpdateWidget(QueueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _failureCursors.clear();
    }
  }

  @override
  void dispose() {
    _rowsController.dispose();
    super.dispose();
  }

  void _failurePage(QueueFailureCursor? next) {
    refresh(() {
      if (next == null) {
        _failureCursors.removeLast();
      } else {
        _failureCursors.add(next);
      }
    });
    if (_rowsController.hasClients) {
      _rowsController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Set<String> picked = ref.watch(queueSelectionProvider);
    final String? projectId = widget.projectId;
    final AsyncValue<QueueSnapshot> value = projectId == null
        ? ref.watch(queueSnapshotProvider)
        : ref.watch(queueSnapshotForProjectProvider(projectId));
    final ProcessingBatchState batch = ref.watch(processingControllerProvider);
    final QueueSnapshot? loaded = value.value;
    final query = (
      projectId: widget.projectId,
      after: _failureCursors.isEmpty ? null : _failureCursors.last,
    );
    final AsyncValue<QueueFailurePage> failed = (loaded?.failed ?? 0) == 0
        ? const AsyncData<QueueFailurePage>(QueueFailurePage())
        : ref.watch(queueFailurePageProvider(query));
    final Set<String> selected = loaded == null
        ? const <String>{}
        : _selected(picked, loaded);
    return AppPage(
      key: const ValueKey<String>('route-queue'),
      title: localCopy.queueTitle,
      scrollable: false,
      footer: loaded == null || (_nothingWaiting(loaded) && !batch.isRunning)
          ? null
          : ProcessActions(
              running: batch.isRunning,
              selectedCount: selected.length,
              onProcessAll: loaded.queued == 0 && loaded.unprocessed == 0
                  ? null
                  : () => _process(const <String>[]),
              onProcessSelected: selected.isEmpty
                  ? null
                  : () => _process(selected.toList(growable: false)),
              onCancel: ref.read(processingControllerProvider.notifier).cancel,
            ),
      body: AsyncValueView<QueueSnapshot>(
        value: value,
        onRetry: () => projectId == null
            ? ref.invalidate(queueSnapshotProvider)
            : ref.invalidate(queueSnapshotForProjectProvider(projectId)),
        // A finished run keeps its summary on screen even once the queue
        // has emptied.
        isEmpty: (QueueSnapshot snapshot) =>
            _nothingWaiting(snapshot) && batch.steps.isEmpty,
        empty: () {
          final LocalizedCopy localCopy = Copy.of(context);

          return AppEmptyState(
            icon: AppIcons.empty,
            headline: localCopy.queueEmptyHeadline,
            message: localCopy.queueEmptyMessage,
            actionLabel: localCopy.recordsEmptyAction,
            onAction: _capture,
          );
        },
        data: (QueueSnapshot snapshot) {
          final LocalizedCopy localCopy = Copy.of(context);
          final QueueFailurePage? page = failed.asData?.value;

          final List<_QueueRow> rows = <_QueueRow>[
            const _QueueRow.summary(),
            if (snapshot.failed > 0)
              _QueueRow.header(localCopy.queueFailedTitle),
            if (snapshot.failed > 0 && page == null)
              _QueueRow.content(
                AsyncValueView<QueueFailurePage>(
                  value: failed,
                  onRetry: () =>
                      ref.invalidate(queueFailurePageProvider(query)),
                  data: (_) => const SizedBox.shrink(),
                ),
              ),
            for (final QueueFailure failure
                in page?.items ?? const <QueueFailure>[])
              _QueueRow.failure(failure),
            if (snapshot.failed > 0 &&
                (_failureCursors.isNotEmpty || page?.nextCursor != null))
              _QueueRow.content(
                Padding(
                  padding: EdgeInsets.all(AppPage.gutter(context)),
                  child: Wrap(
                    spacing: Space.x2,
                    runSpacing: Space.x2,
                    children: <Widget>[
                      AppButton(
                        key: const ValueKey<String>('queue-failures-previous'),
                        label: localCopy.pdfPreviousPage,
                        variant: AppButtonVariant.secondary,
                        onPressed: _failureCursors.isEmpty
                            ? null
                            : () => _failurePage(null),
                      ),
                      AppButton(
                        key: const ValueKey<String>('queue-failures-next'),
                        label: localCopy.pdfNextPage,
                        variant: AppButtonVariant.secondary,
                        onPressed: page?.nextCursor == null
                            ? null
                            : () => _failurePage(page!.nextCursor),
                      ),
                    ],
                  ),
                ),
              ),
            if (snapshot.groups.isNotEmpty)
              _QueueRow.header(localCopy.queueGroupsTitle),
            for (final QueueGroup group in snapshot.groups)
              _QueueRow.group(group),
          ];
          return ListView.builder(
            key: const ValueKey<String>('queue-rows'),
            controller: _rowsController,
            padding: const EdgeInsets.only(bottom: Space.x4),
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int index) {
              return ContentConstraint(
                child: _row(
                  context,
                  rows[index],
                  snapshot: snapshot,
                  batch: batch,
                  selected: selected,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext context,
    _QueueRow row, {
    required QueueSnapshot snapshot,
    required ProcessingBatchState batch,
    required Set<String> selected,
  }) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool running = batch.isRunning;
    if (row.content != null) {
      return row.content!;
    }
    final QueueFailure? failure = row.failure;
    final QueueGroup? group = row.group;
    final String? header = row.header;
    if (failure != null) {
      final ProcessingJob job = failure.job;
      final String record = failure.name.trim().isNotEmpty
          ? failure.name
          : localCopy.recordsUntitled(failure.number);
      return AppListTile(
        key: ValueKey<String>('queue-failure-${job.id}'),
        title: record,
        subtitle: job.localizedLastError == null
            ? (job.lastError ?? localCopy.queueFailed)
            : localCopy.resolve(job.localizedLastError!),
        status: const AppStatusPill.badge(status: RecordStatus.failed),
        onTap: () => _open(job.recordId),
        trailing: AppIconButton(
          key: ValueKey<String>('queue-retry-${job.id}'),
          icon: AppIcons.processing,
          semanticLabel: localCopy.queueRetryLabel(record),
          tooltip: localCopy.queueRetry,
          onPressed: running
              ? null
              : () => ref
                    .read(processingControllerProvider.notifier)
                    .retry(job.id),
        ),
      );
    }
    if (group != null) {
      return AppListTile(
        key: ValueKey<String>('queue-group-${group.label}'),
        leading: const Icon(AppIcons.project),
        title: group.label,
        subtitle: localCopy.recordsCount(group.records),
        selected: selected.contains(group.label),
        onTap: running
            ? null
            : () =>
                  ref.read(queueSelectionProvider.notifier).toggle(group.label),
      );
    }
    if (header != null) {
      return AppSectionHeader(title: header);
    }
    return _QueueSummary(snapshot: snapshot, batch: batch);
  }

  /// Captures a record: in this project when the queue is scoped to one.
  void _capture() {
    final String? projectId = widget.projectId;
    if (projectId == null) {
      context.go(RoutePaths.captureRoot);
      return;
    }
    context.push(RoutePaths.projectCapture(projectId));
  }

  /// Opens the record a failed job belongs to.
  void _open(String recordId) {
    final String? projectId = widget.projectId;
    context.push(
      projectId == null
          ? RoutePaths.record(recordId)
          : RoutePaths.projectRecord(projectId, recordId),
    );
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

/// Whether [snapshot] has nothing to process and nothing failed.
bool _nothingWaiting(QueueSnapshot snapshot) {
  return snapshot.unprocessed == 0 &&
      snapshot.queued == 0 &&
      snapshot.failed == 0 &&
      snapshot.groups.isEmpty;
}

/// The picked groups still on [snapshot]: a group that has emptied out
/// cannot stay selected.
Set<String> _selected(Set<String> picked, QueueSnapshot snapshot) {
  return picked.intersection(<String>{
    for (final QueueGroup group in snapshot.groups) group.label,
  });
}

/// The one summary at the top of the queue: the browser notice when
/// on-device reading is unavailable, the three counts, today's online
/// usage, and the running or finished batch.
class _QueueSummary extends ConsumerWidget {
  const _QueueSummary({required this.snapshot, required this.batch});

  final QueueSnapshot snapshot;
  final ProcessingBatchState batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool noOnDeviceReading = ref.watch(
      onDeviceReadingUnavailableProvider,
    );
    final double gutter = AppPage.gutter(context);
    return Padding(
      key: const ValueKey<String>('queue-summary'),
      padding: EdgeInsets.fromLTRB(gutter, Space.x2, gutter, Space.x0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (noOnDeviceReading) ...<Widget>[
            AppBanner(
              key: const ValueKey<String>('queue-browser-notice'),
              message: localCopy.ocrBrowserUnavailable,
              icon: AppIcons.info,
              tone: SnackTone.info,
            ),
            const SizedBox(height: Space.x2),
          ],
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: <Widget>[
              AppStatusPill(
                status: RecordStatus.captured,
                label: localCopy.queueUnprocessedCount(snapshot.unprocessed),
              ),
              AppStatusPill(
                status: RecordStatus.queued,
                label: localCopy.queueQueuedCount(snapshot.queued),
              ),
              AppStatusPill(
                status: RecordStatus.failed,
                label: localCopy.queueFailedCount(snapshot.failed),
              ),
            ],
          ),
          const SizedBox(height: Space.x2),
          Text(
            localCopy.queueUsage(
              snapshot.requestsToday,
              snapshot.imagesToday,
              snapshot.requestCap,
            ),
          ),
          ProcessBatchLine(batch: batch),
        ],
      ),
    );
  }
}

/// One row of the queue list: the summary, a section header, a failed job
/// or a group.
final class _QueueRow {
  const _QueueRow.summary()
    : header = null,
      failure = null,
      group = null,
      content = null;

  const _QueueRow.header(String this.header)
    : failure = null,
      group = null,
      content = null;

  const _QueueRow.failure(QueueFailure this.failure)
    : header = null,
      group = null,
      content = null;

  const _QueueRow.group(QueueGroup this.group)
    : header = null,
      failure = null,
      content = null;

  const _QueueRow.content(Widget this.content)
    : header = null,
      failure = null,
      group = null;

  final String? header;
  final QueueFailure? failure;
  final QueueGroup? group;
  final Widget? content;
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
