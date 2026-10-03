import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/quality_counts.dart';
import 'quality_providers.dart';

/// What still blocks a clean export of one project (task 015), each count
/// opening the screen that clears it.
///
/// Invalid and unreviewed records open the review queue, duplicate pairs the
/// duplicates screen and merge conflicts the project's records, where the
/// conflict flag shows. A clean project says so and offers the export.
final class QualitySummaryScreen extends ConsumerWidget {
  /// Creates the summary of [projectId].
  const QualitySummaryScreen({required this.projectId, super.key});

  /// The project summarised.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppPage(
      key: const ValueKey<String>('route-quality'),
      title: localCopy.qualitySummaryTitle,
      inset: false,
      overflow: <AppOverflowAction>[
        AppOverflowAction(
          key: const ValueKey<String>('quality-variances'),
          label: localCopy.varianceTitle,
          icon: AppIcons.review,
          onTap: () =>
              unawaited(context.push(RoutePaths.projectVariance(projectId))),
        ),
      ],
      body: AsyncValueView<QualityCounts>(
        value: ref.watch(qualityCountsProvider(projectId)),
        onRetry: () => ref.invalidate(qualityCountsProvider(projectId)),
        isEmpty: isExportReady,
        empty: () => AppEmptyState(
          icon: AppIcons.verified,
          headline: Copy.of(context).qualityCleanHeadline,
          message: Copy.of(context).qualityCleanMessage,
          actionLabel: Copy.of(context).projectExport,
          onAction: () =>
              unawaited(context.push(RoutePaths.projectExports(projectId))),
        ),
        data: (QualityCounts counts) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Count(
              keyName: 'quality-invalid',
              title: Copy.of(context).qualityInvalid,
              count: counts.invalid,
              route: RoutePaths.projectBatchReview(projectId),
            ),
            _Count(
              keyName: 'quality-duplicates',
              title: Copy.of(context).qualityDuplicates,
              count: counts.duplicates,
              route: RoutePaths.projectDuplicates(projectId),
            ),
            _Count(
              keyName: 'quality-conflicts',
              title: Copy.of(context).qualityConflicts,
              count: counts.conflicts,
              route: RoutePaths.projectRecords(projectId),
            ),
            _Count(
              keyName: 'quality-unreviewed',
              title: Copy.of(context).qualityUnreviewed,
              count: counts.unreviewed,
              route: RoutePaths.projectBatchReview(projectId),
            ),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.keyName,
    required this.title,
    required this.count,
    required this.route,
  });

  final String keyName;
  final String title;
  final int count;
  final String route;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }
    return AppListTile(
      key: ValueKey<String>(keyName),
      title: title,
      subtitle: '$count',
      trailing: const Icon(AppIcons.open),
      onTap: () => unawaited(context.push(route)),
    );
  }
}
