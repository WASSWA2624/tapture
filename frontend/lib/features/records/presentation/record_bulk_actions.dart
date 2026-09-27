import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/features/processing/processing.dart'
    show
        ProcessingJob,
        processingControllerProvider,
        processingEgressSummaryProvider,
        showEgressPreview;

import 'record_bulk_controller.dart';
import 'record_delete_action.dart';
import 'record_delete_controller.dart';
import 'record_selection.dart';

/// The action bar over a selection of one project's records (task 014
/// step 8): how many are ticked, select all shown, clear, and approve,
/// archive, delete, export and process again.
///
/// The count shows in the bar and again in every destructive confirm
/// (FE-SIMP-07). Each action applies record by record, so one failure
/// leaves the others changed; a snack then says how many changed and how
/// many did not. Records that changed are unticked and the rest stay
/// ticked, so the operator sees what is left. With nothing ticked the bar
/// draws nothing.
///
/// A narrow bar keeps approve and delete in reach and puts the rest behind
/// its overflow control; a wide one shows every action.
final class RecordBulkActions extends ConsumerWidget {
  /// Creates the bar over [projectId]'s selection.
  const RecordBulkActions({
    required this.projectId,
    this.selectable = const <String>[],
    this.onExport,
    super.key,
  });

  /// The project whose ticked records the bar acts on.
  final String projectId;

  /// The records the list has shown, which Select all shown ticks. Select
  /// all is offered only while one of them is not ticked.
  final List<String> selectable;

  /// Exports the ticked records, once the operator has confirmed. Null
  /// opens the project's export page: an export is one package of the whole
  /// project (task 076, D13), so the confirm says the selection travels with
  /// every other record of the project.
  final ValueChanged<List<String>>? onExport;

  /// Runs [projectId]'s processing queue now, in the foreground, as the
  /// queue's Process all does: records put back in the queue are read
  /// again rather than waiting for the next unattended run (D14).
  ///
  /// Before the session's first online step the operator sees what would
  /// leave the device. A record whose template only the operator can choose
  /// is set aside and waits in the queue, where Process asks. A batch
  /// already running picks the queued jobs up instead.
  static Future<void> processQueued(
    BuildContext context, {
    required String projectId,
  }) {
    return _processQueued(
      ProviderScope.containerOf(context, listen: false),
      _snackHost(context),
      projectId,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> selected = ref.watch(recordSelectionProvider(projectId));
    if (selected.isEmpty) {
      return const SizedBox.shrink();
    }
    final bool busy =
        ref.watch(recordBulkControllerProvider(projectId)) != null ||
        ref.watch(recordDeleteControllerProvider);
    final List<String> ids = List<String>.unmodifiable(selected);
    final int count = ids.length;
    final bool canSelectMore = selectable.any(
      (String id) => !selected.contains(id),
    );
    final List<_BulkCommand> commands = <_BulkCommand>[
      if (canSelectMore)
        _BulkCommand(
          key: 'records-bulk-select-all',
          icon: AppIcons.selectAll,
          label: Copy.recordsSelectAllShown,
          inReach: false,
          run: () => ref
              .read(recordSelectionProvider(projectId).notifier)
              .selectAll(selectable),
        ),
      _BulkCommand(
        key: 'records-bulk-approve',
        icon: AppIcons.verified,
        label: Copy.recordsApproveLabel(count),
        inReach: true,
        run: () => unawaited(_approve(context, ref, ids)),
      ),
      _BulkCommand(
        key: 'records-bulk-archive',
        icon: AppIcons.archive,
        label: Copy.recordsArchiveLabel(count),
        inReach: false,
        run: () => unawaited(_archive(context, ref, ids)),
      ),
      _BulkCommand(
        key: 'records-bulk-reprocess',
        icon: AppIcons.processing,
        label: Copy.recordsReprocessLabel(count),
        inReach: false,
        run: () => unawaited(_reprocess(context, ref, ids)),
      ),
      _BulkCommand(
        key: 'records-bulk-export',
        icon: AppIcons.export,
        label: Copy.recordsExportLabel(count),
        inReach: false,
        run: () => unawaited(_export(context, ids)),
      ),
      _BulkCommand(
        key: 'records-bulk-delete',
        icon: AppIcons.delete,
        label: Copy.recordsDeleteLabel(count),
        inReach: true,
        run: () => unawaited(_delete(context, ref, ids)),
      ),
    ];
    final AppColors colors = context.colors;
    return DecoratedBox(
      key: const ValueKey<String>('records-bulk-bar'),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x2,
          vertical: Space.x1,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= _inlineWidth;
            final List<_BulkCommand> inline = <_BulkCommand>[
              for (final _BulkCommand command in commands)
                if (wide || command.inReach) command,
            ];
            final List<_BulkCommand> tucked = <_BulkCommand>[
              for (final _BulkCommand command in commands)
                if (!wide && !command.inReach) command,
            ];
            return Row(
              children: <Widget>[
                AppIconButton(
                  key: const ValueKey<String>('records-bulk-clear'),
                  icon: AppIcons.close,
                  semanticLabel: Copy.recordsClearSelection,
                  tooltip: Copy.recordsClearSelection,
                  outlined: false,
                  onPressed: busy
                      ? null
                      : ref
                            .read(recordSelectionProvider(projectId).notifier)
                            .clear,
                ),
                const SizedBox(width: Space.x2),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      Copy.recordsSelectedCount(count),
                      key: const ValueKey<String>('records-bulk-count'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),
                for (final _BulkCommand command in inline) ...<Widget>[
                  const SizedBox(width: Space.x1),
                  AppIconButton(
                    key: ValueKey<String>(command.key),
                    icon: command.icon,
                    semanticLabel: command.label,
                    tooltip: command.label,
                    onPressed: busy ? null : command.run,
                  ),
                ],
                if (tucked.isNotEmpty) ...<Widget>[
                  const SizedBox(width: Space.x1),
                  AppOverflowMenu(
                    key: const ValueKey<String>('records-bulk-more'),
                    items: busy
                        ? const <AppOverflowAction>[]
                        : <AppOverflowAction>[
                            for (final _BulkCommand command in tucked)
                              AppOverflowAction(
                                key: ValueKey<String>(command.key),
                                label: command.label,
                                icon: command.icon,
                                onTap: command.run,
                              ),
                          ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Approves the ticked records; the lifecycle refuses the ones that may
  /// not be approved yet, and they stay ticked.
  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    final RecordBulkController controller = ref.read(
      recordBulkControllerProvider(projectId).notifier,
    );
    final BuildContext host = _snackHost(context);
    final RecordBulkOutcome outcome = await controller.approve(ids);
    if (context.mounted) {
      _settle(ref, outcome);
    }
    if (host.mounted) {
      _report(
        host,
        outcome,
        done: Copy.recordsApproved,
        notDone: Copy.recordsNotApproved,
      );
    }
  }

  /// Confirms, naming the count, then archives the ticked records.
  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    final RecordBulkController controller = ref.read(
      recordBulkControllerProvider(projectId).notifier,
    );
    final BuildContext host = _snackHost(context);
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.recordsArchiveTitle(ids.length),
      message: Copy.recordsArchiveMessage(ids.length),
      confirmLabel: Copy.recordsArchiveConfirm,
      destructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final RecordBulkOutcome outcome = await controller.archive(ids);
    if (context.mounted) {
      _settle(ref, outcome);
    }
    if (host.mounted) {
      _report(
        host,
        outcome,
        done: Copy.recordsArchived,
        notDone: Copy.recordsNotArchived,
      );
    }
  }

  /// Deletes the ticked records to the recycle bin through the one delete
  /// flow: its confirm names the count, and its snack reports and undoes.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    final RecordDeleteOutcome? outcome = await RecordDeleteAction.run(
      context,
      ref,
      ids: ids,
    );
    if (outcome != null) {
      if (context.mounted) {
        _settle(ref, outcome);
      }
    }
  }

  /// Confirms, naming the count, puts the ticked records back in the
  /// processing queue, and runs the queue unless the device is offline.
  Future<void> _reprocess(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    final RecordBulkController controller = ref.read(
      recordBulkControllerProvider(projectId).notifier,
    );
    final ProviderContainer container = ProviderScope.containerOf(
      context,
      listen: false,
    );
    final BuildContext host = _snackHost(context);
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.recordsReprocessTitle(ids.length),
      message: Copy.recordsReprocessMessage(ids.length),
      confirmLabel: Copy.recordsReprocessConfirm,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final RecordBulkOutcome outcome = await controller.reprocess(ids);
    final bool offline = container.read(offlineNowProvider);
    final int queued = outcome.succeeded.length;
    if (context.mounted) {
      _settle(ref, outcome);
    }
    if (host.mounted) {
      _report(
        host,
        outcome,
        done: Copy.recordsRequeued,
        notDone: Copy.recordsNotRequeued,
        after: offline && queued > 0
            ? Copy.recordsRequeuedOffline(queued)
            : null,
      );
    }
    if (queued > 0 && !offline && host.mounted) {
      unawaited(_processQueued(container, host, projectId));
    }
  }

  /// Confirms what an export holds, naming the count, then hands the ticked
  /// records to [onExport] or opens the project's export page.
  Future<void> _export(BuildContext context, List<String> ids) async {
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.recordsExportTitle(ids.length),
      message: Copy.recordsExportMessage(ids.length),
      confirmLabel: Copy.recordsExportConfirm,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final ValueChanged<List<String>>? export = onExport;
    if (export != null) {
      export(ids);
      return;
    }
    unawaited(context.push(RoutePaths.projectExports(projectId)));
  }

  /// Unticks the records a bulk action changed; the ones it could not
  /// change stay ticked. Callers check the bar is still mounted first: once
  /// it has gone, the selection has gone with the list.
  void _settle(WidgetRef ref, RecordBulkOutcome outcome) {
    if (outcome.succeeded.isEmpty) {
      return;
    }
    ref
        .read(recordSelectionProvider(projectId).notifier)
        .deselectAll(outcome.succeeded);
  }
}

/// The narrowest bar that shows every action inline: the clear control,
/// a short count and six actions, each a 48dp target.
const double _inlineWidth = Sizes.minTapTarget * 12;

/// One action on the bar: its control, its label, and whether a narrow bar
/// keeps it in reach rather than behind the overflow control.
final class _BulkCommand {
  const _BulkCommand({
    required this.key,
    required this.icon,
    required this.label,
    required this.inReach,
    required this.run,
  });

  final String key;
  final IconData icon;
  final String label;
  final bool inReach;
  final VoidCallback run;
}

/// A context that outlives the bar: once the records it acted on are
/// unticked, or have left the list, the bar may be gone. The root navigator
/// sits under the app's theme and scaffold messenger, so a snack shown from
/// it lands where the operator is looking.
BuildContext _snackHost(BuildContext context) {
  return Navigator.maybeOf(context, rootNavigator: true)?.context ?? context;
}

/// The snack after a bulk action: the count that changed, the count that
/// did not as well when some failed, or why when none changed. [after] is a
/// sentence added at the end.
void _report(
  BuildContext host,
  RecordBulkOutcome outcome, {
  required String Function(int n) done,
  required String Function(int n) notDone,
  String? after,
}) {
  final int changed = outcome.succeeded.length;
  final int failed = outcome.failed.length;
  if (changed == 0 && failed == 0) {
    return;
  }
  final String text;
  final SnackTone tone;
  if (changed == 0) {
    // One record's own failure says why; several are counted.
    text = failed == 1 ? outcome.failed.values.single.message : notDone(failed);
    tone = SnackTone.error;
  } else if (failed == 0) {
    text = done(changed);
    tone = SnackTone.success;
  } else {
    text = Copy.recordsBulkOutcome(
      done: done(changed),
      notDone: notDone(failed),
    );
    tone = SnackTone.warning;
  }
  showAppSnack(
    host,
    after == null ? text : _sentences(text, after),
    tone: tone,
  );
}

/// [first] and [second] as one line of sentences.
String _sentences(String first, String second) {
  return first.endsWith('.') ? '$first $second' : '$first. $second';
}

/// Holds the processing batch alive until it ends, however soon the bar or
/// the list that started it goes, and runs [projectId]'s queue.
Future<void> _processQueued(
  ProviderContainer container,
  BuildContext host,
  String projectId,
) async {
  final ProviderSubscription<Object> hold = container.listen<Object>(
    processingControllerProvider.notifier,
    (Object? _, Object _) {},
  );
  try {
    await container
        .read(processingControllerProvider.notifier)
        .process(
          projectId: projectId,
          confirmOnline: (ProcessingJob job) =>
              _confirmOnline(container, host, job),
        );
  } finally {
    hold.close();
  }
}

/// The egress preview before the session's first online step, as the queue
/// shows it. A job with nothing to send goes ahead without asking.
Future<bool> _confirmOnline(
  ProviderContainer container,
  BuildContext host,
  ProcessingJob job,
) async {
  final ({int imageCount, int payloadBytes}) summary = await container.read(
    processingEgressSummaryProvider,
  )(job);
  if (summary.imageCount == 0 && summary.payloadBytes == 0) {
    return true;
  }
  if (!host.mounted) {
    return false;
  }
  return showEgressPreview(
    host,
    imageCount: summary.imageCount,
    payloadBytes: summary.payloadBytes,
  );
}
