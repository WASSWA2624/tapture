import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
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

/// The recycle bin (task 014 step 7, D12): every deleted record across
/// projects, newest deletion first, with its project, when it was deleted
/// and the days it has left before the purge removes it for good.
///
/// One press restores a record whole, to the status it had. Empty recycle
/// bin removes everything now behind a strong confirm that names the count
/// and must be typed; a record a merge still needs is kept even then. Where
/// no purge runs, as in previews, the action is off and says why.
final class RecycleBinScreen extends ConsumerWidget {
  /// Creates the recycle bin page.
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DeletedRecord>> bin = ref.watch(recycleBinProvider);
    final int days = ref.watch(recordRetentionDaysProvider);
    final RecycleBinActivity activity = ref.watch(recycleBinControllerProvider);
    final bool canEmpty = ref.watch(recordPurgeJobProvider) != null;
    final List<DeletedRecord> held =
        bin.asData?.value ?? const <DeletedRecord>[];
    return AppPage(
      key: const ValueKey<String>('route-recycle-bin'),
      title: Copy.recycleBinTitle,
      scrollable: false,
      inset: false,
      footer: held.isEmpty
          ? null
          : _EmptyNowBar(
              available: canEmpty,
              emptying: activity.emptying,
              onEmpty: () => unawaited(_emptyNow(context, ref, held.length)),
            ),
      body: AsyncValueView<List<DeletedRecord>>(
        value: bin,
        onRetry: () => ref.invalidate(recycleBinProvider),
        isEmpty: (List<DeletedRecord> rows) => rows.isEmpty,
        empty: () => AppEmptyState(
          icon: AppIcons.restore,
          headline: Copy.recycleBinEmptyHeadline,
          message: Copy.recycleBinEmptyMessage(days),
        ),
        data: (List<DeletedRecord> rows) =>
            _BinList(rows: rows, days: days, activity: activity),
      ),
    );
  }

  /// Confirms with the count typed, empties the recycle bin, and reports
  /// what went, what a merge kept, and what failed.
  Future<void> _emptyNow(BuildContext context, WidgetRef ref, int count) async {
    final RecycleBinController controller = ref.read(
      recycleBinControllerProvider.notifier,
    );
    final BuildContext host = _snackHost(context);
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.recycleBinEmptyTitle(count),
      message: Copy.recycleBinEmptyWarning(count),
      confirmLabel: Copy.recycleBinEmptyConfirm,
      destructive: true,
      typedValue: '$count',
      typedLabel: Copy.recycleBinEmptyTypeCount(count),
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
          Copy.recycleBinEmptied(
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
  });

  final List<DeletedRecord> rows;
  final int days;
  final RecycleBinActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = ref.watch(recordClockProvider).nowUtc();
    final double gutter = AppPage.gutter(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.x2, gutter, Space.x2),
          child: Text(
            Copy.recycleBinKeptFor(days),
            style: AppText.caption.copyWith(color: context.colors.onSurface),
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const ValueKey<String>('recycle-bin-list'),
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int index) {
              final DeletedRecord record = rows[index];
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
    final RecordSummary summary = record.summary;
    final bool named = summary.name.trim().isNotEmpty;
    final String title = named
        ? summary.name
        : Copy.recordsUntitled(summary.number);
    final RecordPhoto? thumb = summary.thumb;
    return AppListTile(
      key: ValueKey<String>('recycle-bin-row-${record.id}'),
      title: title,
      subtitle: Copy.recycleBinRowSubtitle(
        number: named ? summary.number : null,
        projectName: record.projectName,
        deletedAt: record.deletedAt,
      ),
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
        label: Copy.recycleBinDaysLeft(daysLeft),
      ),
      trailing: AppIconButton(
        key: ValueKey<String>('recycle-bin-restore-${record.id}'),
        icon: AppIcons.restore,
        semanticLabel: Copy.recycleBinRestoreLabel(title),
        tooltip: Copy.recycleBinRestore,
        onPressed: restoring || locked
            ? null
            : () => unawaited(_restore(context, ref)),
      ),
    );
  }

  /// Restores the record in one press and says so; the row leaves the bin.
  Future<void> _restore(BuildContext context, WidgetRef ref) async {
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
        showAppSnack(host, Copy.recordsRestored(1), tone: SnackTone.success);
      case FailureResult<void>(:final Failure failure):
        showAppSnack(host, failure.message, tone: SnackTone.error);
    }
  }
}

/// Empty recycle bin, pinned under the list. Off, with the reason above
/// it, where no purge runs; busy while the bin is being emptied.
class _EmptyNowBar extends StatelessWidget {
  const _EmptyNowBar({
    required this.available,
    required this.emptying,
    required this.onEmpty,
  });

  final bool available;
  final bool emptying;
  final VoidCallback onEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!available) ...<Widget>[
          Text(
            Copy.recycleBinEmptyUnavailable,
            key: const ValueKey<String>('recycle-bin-empty-unavailable'),
            style: AppText.caption.copyWith(color: context.colors.onSurface),
          ),
          const SizedBox(height: Space.x2),
        ],
        AppButton(
          key: const ValueKey<String>('recycle-bin-empty'),
          label: Copy.recycleBinEmpty,
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
