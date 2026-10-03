import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/field_variance.dart';
import '../domain/record_variance.dart';
import '../domain/uncaptured_rows.dart';
import 'duplicate_flow.dart';
import 'quality_providers.dart';
import 'variance_filter_controller.dart';

/// The deliverable view of a verification exercise (task 015): what differs
/// between the register and what was found, for one record or across a
/// project, filtered by status and grouped by context level.
///
/// Every row is readable without opening its record and opens it on tap.
/// The missing filter also lists register rows no record came from and
/// checklist rows never captured.
final class VarianceScreen extends ConsumerWidget {
  /// Creates the view of [projectId], limited to [recordId] when given.
  const VarianceScreen({required this.projectId, this.recordId, super.key});

  /// The project read.
  final String projectId;

  /// When set, only this record's rows are shown.
  final String? recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final VarianceStatus? filter = ref.watch(
      varianceFilterControllerProvider(projectId),
    );
    return AppPage(
      key: const ValueKey<String>('route-variance'),
      title: localCopy.varianceTitle,
      inset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppPage.gutter(context),
              vertical: Space.x2,
            ),
            child: AppChipRow(
              chips: <AppChip>[
                for (final VarianceStatus status in VarianceStatus.values)
                  AppChip(
                    key: ValueKey<String>('variance-filter-${status.name}'),
                    label: varianceLabel(
                      status,
                      localizedCopy: Copy.of(context),
                    ),
                    selected: filter == status,
                    onTap: () => ref
                        .read(
                          varianceFilterControllerProvider(projectId).notifier,
                        )
                        .toggle(status),
                  ),
              ],
            ),
          ),
          AsyncValueView<List<RecordVariance>>(
            value: ref.watch(projectVariancesProvider(projectId)),
            onRetry: () => ref.invalidate(projectVariancesProvider(projectId)),
            data: (List<RecordVariance> rows) => _rows(context, rows, filter),
          ),
          if (filter == VarianceStatus.missing && recordId == null)
            AsyncValueView<UncapturedRows>(
              value: ref.watch(missingItemsProvider(projectId)),
              onRetry: () => ref.invalidate(missingItemsProvider(projectId)),
              data: (UncapturedRows rows) => _missing(context, rows),
            ),
        ],
      ),
    );
  }

  Widget _rows(
    BuildContext context,
    List<RecordVariance> rows,
    VarianceStatus? filter,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? recordId = this.recordId;
    final List<RecordVariance> shown = <RecordVariance>[
      for (final RecordVariance row in rows)
        if ((recordId == null || row.recordId == recordId) &&
            (filter == null || row.status == filter))
          row,
    ];
    if (shown.isEmpty) {
      if (filter == VarianceStatus.missing && recordId == null) {
        return const SizedBox.shrink();
      }
      return AppEmptyState(
        icon: AppIcons.review,
        headline: localCopy.varianceEmptyHeadline,
        message: localCopy.varianceEmptyMessage,
        actionLabel: localCopy.varianceOpenRecords,
        onAction: () => context.go(RoutePaths.projectRecords(projectId)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MapEntry<String, List<RecordVariance>> group in _byContext(
          shown,
          localizedCopy: Copy.of(context),
        ).entries) ...<Widget>[
          AppSectionHeader(title: group.key),
          for (final RecordVariance row in group.value)
            AppListTile(
              key: ValueKey<String>('variance-${row.id}'),
              title: recordId == null
                  ? '${DuplicateFlow.title(row.recordName, row.recordNumber, localizedCopy: Copy.of(context))}'
                        ' · ${row.label}'
                  : row.label,
              subtitle: localCopy.varianceDetail(
                varianceLabel(row.status, localizedCopy: Copy.of(context)),
                row.recorded,
                row.found,
              ),
              onTap: () => unawaited(
                context.push(RoutePaths.projectRecord(projectId, row.recordId)),
              ),
            ),
        ],
      ],
    );
  }

  Widget _missing(BuildContext context, UncapturedRows missing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (missing.registerNotFound.isNotEmpty) ...<Widget>[
          AppSectionHeader(title: Copy.of(context).varianceRegisterNotFound),
          for (final String label in missing.registerNotFound)
            AppListTile(dense: true, title: label),
        ],
        if (missing.checklistNotCaptured.isNotEmpty) ...<Widget>[
          AppSectionHeader(
            title: Copy.of(context).varianceChecklistNotCaptured,
          ),
          for (final String label in missing.checklistNotCaptured)
            AppListTile(dense: true, title: label),
        ],
      ],
    );
  }
}

/// The label [status] carries on a chip and a row.
String varianceLabel(VarianceStatus status, {LocalizedCopy? localizedCopy}) {
  return switch (status) {
    VarianceStatus.match => (localizedCopy ?? Copy.english).varianceMatch,
    VarianceStatus.changed => (localizedCopy ?? Copy.english).varianceChanged,
    VarianceStatus.missing => (localizedCopy ?? Copy.english).varianceMissing,
  };
}

/// [rows] by context level, in the order they arrived; a record captured
/// without context is filed under the screen's own title.
Map<String, List<RecordVariance>> _byContext(
  List<RecordVariance> rows, {
  LocalizedCopy? localizedCopy,
}) {
  final Map<String, List<RecordVariance>> grouped =
      <String, List<RecordVariance>>{};
  for (final RecordVariance row in rows) {
    final String key = row.context.isEmpty
        ? (localizedCopy ?? Copy.english).varianceTitle
        : row.context;
    grouped.putIfAbsent(key, () => <RecordVariance>[]).add(row);
  }
  return grouped;
}
