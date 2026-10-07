import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/deleted_record.dart';
import '../domain/purge_report.dart';
import '../domain/record_photo.dart';
import '../domain/record_summary.dart';
import 'record_providers.dart';
import 'recycle_bin_controller.dart';

/// Deleted projects, records and managed files, newest deletion first.
/// Parents suppress their children. Retention and permanent removal apply
/// only to records; the destructive confirmation names their count.
final class RecycleBinScreen extends ConsumerWidget {
  /// Creates the recycle bin page.
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<List<DeletedEntity>> bin = ref.watch(deletedEntitiesProvider);
    final int days = ref.watch(recordRetentionDaysProvider);
    final RecycleBinActivity activity = ref.watch(recycleBinControllerProvider);
    final bool canEmpty = ref.watch(recordPurgeJobProvider) != null;
    final int recordCount = bin.asData?.value.where((DeletedEntity row) => row.kind == DeletedEntityKind.record).length ?? 0;
    final Map<String, DeletedRecord> records = <String, DeletedRecord>{
      for (final DeletedRecord record in ref.watch(recycleBinProvider).asData?.value ?? const <DeletedRecord>[]) record.id: record,
    };
    return AppPage(
      key: const ValueKey<String>('route-recycle-bin'),
      title: localCopy.recycleBinTitle,
      scrollable: false,
      inset: false,
      footer: recordCount == 0
          ? null
          : _EmptyNowBar(
              available: canEmpty,
              emptying: activity.emptying,
              count: recordCount,
              onEmpty: () => unawaited(_emptyNow(context, ref, recordCount)),
            ),
      body: AsyncValueView<List<DeletedEntity>>(
        value: bin,
        onRetry: () => ref.read(recycleBinControllerProvider.notifier).refresh(),
        isEmpty: (List<DeletedEntity> rows) => rows.isEmpty,
        empty: () => AppEmptyState(
          icon: AppIcons.restore,
          headline: Copy.of(context).recycleBinEmptyHeadline,
          message: Copy.of(context).recycleBinEmptyMessage(days),
          actionLabel: Copy.of(context).navRecords,
          onAction: () => context.go(RoutePaths.records),
        ),
        data: (List<DeletedEntity> rows) =>
            _BinList(rows: rows, records: records, days: days, activity: activity),
      ),
    );
  }

  /// Confirms with the count typed, empties the recycle bin, and reports
  /// what went, what a merge kept, and what failed.
  Future<void> _emptyNow(BuildContext context, WidgetRef ref, int count) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final RecycleBinController controller = ref.read(
      recycleBinControllerProvider.notifier,
    );
    final BuildContext host = _snackHost(context);
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.recycleBinEmptyTitle(count),
      message: localCopy.recycleBinEmptyWarning(count),
      confirmLabel: localCopy.recycleBinEmptyConfirm,
      destructive: true,
      typedValue: '$count',
      typedLabel: localCopy.recycleBinEmptyTypeCount(count),
    );
    if (!confirmed) {
      return;
    }
    final Result<PurgeReport> emptied = await controller.emptyNow();
    if (!host.mounted) {
      return;
    }
    switch (emptied) {
      case Success<PurgeReport>(:final PurgeReport value):
        showAppSnack(
          host,
          localCopy.recycleBinEmptied(
            purged: value.purged,
            kept: value.skippedMergeNeeded,
            failed: value.failed,
          ),
          tone: _toneOf(value),
        );
      case FailureResult<PurgeReport>(:final Failure failure):
        showAppSnack(host, failure.message, tone: SnackTone.error);
    }
  }
}

/// Success when everything went, a warning when a merge kept some or some
/// failed beside others that went, an error when nothing could go.
SnackTone _toneOf(PurgeReport report) {
  if (report.failed > 0) {
    return report.purged == 0 ? SnackTone.error : SnackTone.warning;
  }
  return report.skippedMergeNeeded > 0 ? SnackTone.warning : SnackTone.success;
}

/// The recycle bin's rows under the line that says how long they stay.
class _BinList extends ConsumerWidget {
  const _BinList({
    required this.rows,
    required this.days,
    required this.activity,
    required this.records,
  });

  final List<DeletedEntity> rows;
  final Map<String, DeletedRecord> records;
  final int days;
  final RecycleBinActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final DateTime now = ref.watch(recordClockProvider).nowUtc();
    final double gutter = AppPage.gutter(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (rows.any((DeletedEntity row) => row.kind == DeletedEntityKind.record)) Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.x2, gutter, Space.x2),
          child: Text(
            localCopy.recycleBinKeptFor(days),
            style: AppText.caption.copyWith(color: context.colors.onSurface),
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const ValueKey<String>('recycle-bin-list'),
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int index) {
              final DeletedEntity entity = rows[index];
              final DeletedRecord? record = entity.kind == DeletedEntityKind.record ? records[entity.id] : null;
              if (record == null) return _EntityBinRow(entity: entity, restoring: activity.restoring.contains(entity.key));
              return _BinRow(
                record: record,
                daysLeft: record.daysLeft(now: now, retentionDays: days),
                restoring: activity.restoring.contains(record.id),
                locked: activity.emptying,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One deleted record: what it was, where from, when it went, the days it
/// has left, and its restore control.
class _BinRow extends ConsumerWidget {
  const _BinRow({
    required this.record,
    required this.daysLeft,
    required this.restoring,
    required this.locked,
  });

  final DeletedRecord record;
  final int daysLeft;
  final bool restoring;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordSummary summary = record.summary;
    final bool named = summary.name.trim().isNotEmpty;
    final String title = named
        ? summary.name
        : localCopy.recordsUntitled(summary.number);
    final RecordPhoto? thumb = summary.thumb;
    return AppListTile(
      key: ValueKey<String>('recycle-bin-row-${record.id}'),
      title: title,
      subtitle: localCopy.recycleEntitySubtitle(localCopy.recycleTypeRecord, localCopy.recycleBinRowSubtitle(
        number: named ? summary.number : null,
        projectName: record.projectName,
        deletedAt: record.deletedAt,
      )),
      leading: thumb == null
          ? null
          : RecordThumb(
              sha256: thumb.sha256,
              storagePath: thumb.storagePath,
              quarterTurns: thumb.quarterTurns,
              hasCaption: thumb.hasCaption,
            ),
      status: AppStatusPill.badge(
        status: RecordStatus.deleted,
        label: localCopy.recycleBinDaysLeft(daysLeft),
      ),
      trailing: AppIconButton(
        key: ValueKey<String>('recycle-bin-restore-${record.id}'),
        icon: AppIcons.restore,
        semanticLabel: localCopy.recycleBinRestoreLabel(title),
        tooltip: localCopy.recycleBinRestore,
        onPressed: restoring || locked
            ? null
            : () => unawaited(_restore(context, ref)),
      ),
    );
  }

  /// Restores the record in one press and says so; the row leaves the bin.
  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final RecycleBinController controller = ref.read(
      recycleBinControllerProvider.notifier,
    );
    final BuildContext host = _snackHost(context);
    final Result<void> restored = await controller.restore(record.id);
    if (!host.mounted) {
      return;
    }
    switch (restored) {
      case Success<void>():
        showAppSnack(
          host,
          localCopy.recordsRestored(1),
          tone: SnackTone.success,
        );
      case FailureResult<void>(:final Failure failure):
        showAppSnack(host, failure.message, tone: SnackTone.error);
    }
  }
}

/// Projects and independently deleted files have restoration but no purge timer.
class _EntityBinRow extends ConsumerWidget {
  const _EntityBinRow({required this.entity, required this.restoring});
  final DeletedEntity entity;
  final bool restoring;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy copy = Copy.of(context);
    final String type = switch (entity.kind) {
      DeletedEntityKind.project => copy.recycleTypeProject,
      DeletedEntityKind.record => copy.recycleTypeRecord,
      DeletedEntityKind.photo => copy.recycleTypePhoto,
      DeletedEntityKind.document => copy.recycleTypeDocument,
      DeletedEntityKind.audio => copy.recycleTypeAudio,
    };
    return AppListTile(
      key: ValueKey<String>('recycle-bin-row-${entity.key}'),
      title: entity.name.isEmpty ? type : entity.name,
      wrapText: true,
      subtitle: copy.recycleEntitySubtitle(type, copy.recycleBinRowSubtitle(
        number: null, projectName: entity.projectName, deletedAt: entity.deletedAt,
      )),
      trailing: AppIconButton(
        key: ValueKey<String>('recycle-bin-restore-${entity.key}'),
        icon: AppIcons.restore,
        tooltip: copy.recycleBinRestore,
        semanticLabel: copy.recycleBinRestoreLabel(entity.name),
        onPressed: restoring ? null : () => unawaited(_restore(context, ref)),
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final BuildContext host = _snackHost(context);
    final Result<void> result = await ref.read(recycleBinControllerProvider.notifier).restoreEntity(entity);
    if (!host.mounted) return;
    final LocalizedCopy copy = Copy.of(host);
    switch (result) {
      case Success<void>():
        showAppSnack(host, copy.recycleRestored, tone: SnackTone.success);
      case FailureResult<void>(:final Failure failure):
        showAppSnack(host, copy.failureMessage(failure), tone: SnackTone.error);
    }
  }
}

/// Empty deleted records, pinned under the list. Off, with the reason above
/// it, where no purge runs; busy while the bin is being emptied.
class _EmptyNowBar extends StatelessWidget {
  const _EmptyNowBar({
    required this.available,
    required this.emptying,
    required this.onEmpty,
    required this.count,
  });

  final bool available;
  final bool emptying;
  final VoidCallback onEmpty;
  final int count;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!available) ...<Widget>[
          Text(
            localCopy.recycleBinEmptyUnavailable,
            key: const ValueKey<String>('recycle-bin-empty-unavailable'),
            style: AppText.caption.copyWith(color: context.colors.onSurface),
          ),
          const SizedBox(height: Space.x2),
        ],
        AppButton(
          key: const ValueKey<String>('recycle-bin-empty'),
          label: localCopy.recycleEmptyRecords(count),
          icon: AppIcons.delete,
          variant: AppButtonVariant.destructive,
          expand: true,
          busy: emptying,
          onPressed: available && !emptying ? onEmpty : null,
        ),
      ],
    );
  }
}

/// A context that outlives the row or bar that started an action: a
/// restored record leaves the list with its row. The root navigator sits
/// under the app's theme and scaffold messenger, so a snack shown from it
/// lands where the operator is looking.
BuildContext _snackHost(BuildContext context) {
  return Navigator.maybeOf(context, rootNavigator: true)?.context ?? context;
}
