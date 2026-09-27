import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/features/quality/quality.dart'
    hide ConflictChoice, FieldConflict;

import 'merge_controller.dart';
import 'merge_labels.dart';
import 'merge_view.dart';

/// Keeps both records of the open pair.
const ValueKey<String> duplicateKeepBothKey = ValueKey<String>(
  'duplicate-keep-both',
);

/// Leaves the incoming record of the open pair out of the merge.
const ValueKey<String> duplicateSkipKey = ValueKey<String>('duplicate-skip');

/// Shows [pair] side by side, as specification §40.2 lays it out: both
/// records' fields and photo counts, and the signal. Keep both is the
/// default; Don't import leaves the incoming record out (task 076, W22).
Future<void> showDuplicatePairSheet(
  BuildContext context, {
  required String projectId,
  required PossibleDuplicate pair,
}) {
  return showAppSheet<void>(
    context,
    title: Copy.duplicateTitle,
    builder: (BuildContext _) => _PairView(projectId: projectId, pair: pair),
  );
}

class _PairView extends ConsumerWidget {
  const _PairView({required this.projectId, required this.pair});

  final String projectId;
  final PossibleDuplicate pair;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MergeView? view = ref
        .watch(mergeControllerProvider(projectId))
        .asData
        ?.value;
    if (view == null) {
      return const SizedBox.shrink();
    }
    final bool skipped = view.skipped.contains(pair.incomingId);
    final MergeController controller = ref.read(
      mergeControllerProvider(projectId).notifier,
    );
    Future<void> choose({required bool skip}) async {
      await controller.setSkipped(pair.incomingId, skip: skip);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }

    return ListView(
      padding: const EdgeInsets.all(Space.x4),
      children: <Widget>[
        Text(Copy.duplicateSignal(pair.signal.name), style: AppText.bodyStrong),
        const SizedBox(height: Space.x3),
        ResponsivePair(
          matchesHeights: true,
          start: _Side(
            heading: Copy.duplicateIncoming,
            tables: view.bundle.tables,
            recordId: pair.incomingId,
          ),
          end: _Side(
            heading: Copy.duplicateHere,
            tables: view.local,
            recordId: pair.localId,
          ),
        ),
        const SizedBox(height: Space.x4),
        ResponsivePair(
          stacksOnCompact: false,
          matchesHeights: true,
          start: AppButton(
            key: duplicateKeepBothKey,
            label: Copy.duplicateKeepBoth,
            icon: skipped ? null : AppIcons.check,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => unawaited(choose(skip: false)),
          ),
          end: AppButton(
            key: duplicateSkipKey,
            label: Copy.duplicateSkipIncoming,
            icon: skipped ? AppIcons.check : null,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => unawaited(choose(skip: true)),
          ),
        ),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.heading,
    required this.tables,
    required this.recordId,
  });

  final String heading;
  final Map<String, List<Map<String, Object?>>> tables;
  final String recordId;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, Object?>> values = <Map<String, Object?>>[
      for (final Map<String, Object?> row
          in tables['record_fields'] ?? const <Map<String, Object?>>[])
        if (row['record_id'] == recordId) row,
    ];
    final int photos = <Map<String, Object?>>[
      for (final Map<String, Object?> row
          in tables['photos'] ?? const <Map<String, Object?>>[])
        if (row['record_id'] == recordId) row,
    ].length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(heading, style: AppText.label),
          const SizedBox(height: Space.x1),
          Text(mergeRecordLabel(tables, recordId), style: AppText.bodyStrong),
          const SizedBox(height: Space.x2),
          for (final Map<String, Object?> value in values)
            Text(
              Copy.duplicateField(
                '${value['field_key']}',
                '${value['value_final'] ?? value['value_refined'] ?? value['value_raw'] ?? ''}',
              ),
              style: AppText.body,
            ),
          const SizedBox(height: Space.x2),
          Text(Copy.photosCount(photos), style: AppText.caption),
        ],
      ),
    );
  }
}
