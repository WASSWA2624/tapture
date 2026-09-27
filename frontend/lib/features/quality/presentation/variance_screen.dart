import 'package:flutter/widgets.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import '../domain/field_variance.dart';

/// One variance row the screen can group and open.
typedef VarianceRow = ({
  String id,
  String fieldKey,
  String label,
  String context,
  VarianceStatus status,
  String recordId,
});

/// Differences for one record, or across a project (task 015).
final class VarianceScreen extends StatelessWidget {
  /// Creates the screen. [recordId] limits it to one record.
  const VarianceScreen({
    required this.rows,
    this.recordId,
    this.filter,
    this.failure,
    this.onOpen,
    this.onFilter,
    this.onRetry,
    super.key,
  });

  /// Variances to show.
  final List<VarianceRow> rows;

  /// When set, only this record's rows are shown.
  final String? recordId;

  /// The status filter, or null for all.
  final VarianceStatus? filter;

  /// Why the list could not be read.
  final Failure? failure;

  /// Opens the record.
  final ValueChanged<String>? onOpen;

  /// Changes the filter.
  final ValueChanged<VarianceStatus?>? onFilter;

  /// Reads the list again.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    final List<VarianceRow> shown = <VarianceRow>[
      for (final VarianceRow row in rows)
        if ((recordId == null || row.recordId == recordId) &&
            (filter == null || row.status == filter))
          row,
    ];
    return AppPage(
      key: const ValueKey<String>('route-variance'),
      title: Copy.varianceTitle,
      body: failed != null
          ? AppErrorState(failure: failed, onRetry: onRetry)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  spacing: Space.x2,
                  children: <Widget>[
                    for (final VarianceStatus status in VarianceStatus.values)
                      AppChip(
                        key: ValueKey<String>('variance-filter-${status.name}'),
                        label: _label(status),
                        selected: filter == status,
                        onTap: () =>
                            onFilter?.call(filter == status ? null : status),
                      ),
                  ],
                ),
                if (shown.isEmpty)
                  const AppEmptyState(
                    icon: AppIcons.review,
                    headline: Copy.varianceEmptyHeadline,
                    message: Copy.varianceEmptyMessage,
                  )
                else
                  for (final MapEntry<String, List<VarianceRow>> group
                      in _byContext(shown).entries) ...<Widget>[
                    AppSectionHeader(title: group.key),
                    for (final VarianceRow row in group.value)
                      AppListTile(
                        key: ValueKey<String>('variance-${row.id}'),
                        title: row.label,
                        subtitle: _label(row.status),
                        onTap: () => onOpen?.call(row.recordId),
                      ),
                  ],
              ],
            ),
    );
  }
}

Map<String, List<VarianceRow>> _byContext(List<VarianceRow> rows) {
  final Map<String, List<VarianceRow>> grouped = <String, List<VarianceRow>>{};
  for (final VarianceRow row in rows) {
    final String key = row.context.isEmpty ? Copy.varianceTitle : row.context;
    grouped.putIfAbsent(key, () => <VarianceRow>[]).add(row);
  }
  return grouped;
}

String _label(VarianceStatus status) {
  return switch (status) {
    VarianceStatus.match => Copy.varianceMatch,
    VarianceStatus.changed => Copy.varianceChanged,
    VarianceStatus.missing => Copy.varianceMissing,
  };
}
