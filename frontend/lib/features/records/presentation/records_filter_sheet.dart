import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/record_facets.dart';
import '../domain/record_filter.dart';
import '../domain/record_flag.dart';
import 'record_providers.dart';
import 'records_list_controller.dart';
import 'records_page_providers.dart';

/// The facets of one project's records filters (task 014 step 2, D15):
/// status, template, each context level, the capture date range, who
/// captured, condition and the quality flags.
///
/// The choices come from the project's records, read when the sheet opens,
/// with the loading, empty and failure states of [AsyncValueView]. Every
/// choice applies at once through the list's controller, so the list behind
/// the sheet narrows as the operator picks (FE-STATE-04).
final class RecordsFilterSheet extends ConsumerWidget {
  /// Creates the facets of [projectId]'s filters.
  const RecordsFilterSheet({required this.projectId, super.key});

  /// The project whose records are filtered.
  final String projectId;

  /// Opens [projectId]'s records filters in the one filter sheet, with its
  /// Clear filters action turning every filter off (FBK0000003).
  static Future<void> show(BuildContext context, {required String projectId}) {
    final ProviderContainer container = ProviderScope.containerOf(
      context,
      listen: false,
    );
    return showAppFilterSheet(
      context,
      title: Copy.recordsFiltersTitle,
      onClear: container
          .read(recordsListControllerProvider(projectId).notifier)
          .clearFilters,
      facets: (BuildContext _) => RecordsFilterSheet(projectId: projectId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<RecordFacets> facets = ref.watch(
      recordsFacetsProvider(projectId),
    );
    return AsyncValueView<RecordFacets>(
      value: facets,
      onRetry: () => ref.invalidate(recordsFacetsProvider(projectId)),
      isEmpty: (RecordFacets loaded) => loaded.isEmpty,
      empty: () => const AppEmptyState(
        key: ValueKey<String>('records-filters-empty'),
        icon: AppIcons.filter,
        headline: Copy.recordsFiltersEmptyHeadline,
        message: Copy.recordsFiltersEmptyMessage,
      ),
      data: (RecordFacets loaded) {
        return _Facets(projectId: projectId, facets: loaded);
      },
    );
  }
}

/// What a quality flag is called in the filters and on its chip.
String recordFlagLabel(RecordFlag flag) {
  return switch (flag) {
    RecordFlag.hasPhotos => Copy.recordsFlagHasPhotos,
    RecordFlag.hasDuplicate => Copy.recordsFlagHasDuplicate,
    RecordFlag.hasConflict => Copy.recordsFlagHasConflict,
    RecordFlag.hasVariance => Copy.recordsFlagHasVariance,
    RecordFlag.evidenceRemoved => Copy.recordsFlagEvidenceRemoved,
    RecordFlag.mergedFromBundle => Copy.recordsFlagMerged,
  };
}

/// The quality flags an operator can filter by.
const List<RecordFlag> _filterFlags = <RecordFlag>[
  RecordFlag.hasPhotos,
  RecordFlag.hasDuplicate,
  RecordFlag.hasConflict,
  RecordFlag.hasVariance,
  RecordFlag.evidenceRemoved,
];

class _Facets extends ConsumerWidget {
  const _Facets({required this.projectId, required this.facets});

  final String projectId;
  final RecordFacets facets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecordFilter filter = ref
        .watch(recordsListControllerProvider(projectId))
        .filter;
    final RecordsListController controller = ref.read(
      recordsListControllerProvider(projectId).notifier,
    );
    final Clock clock = ref.watch(recordClockProvider);
    final AppColors colors = context.colors;
    void apply(RecordFilter Function(RecordFilter current) change) {
      controller.updateFilter(change);
    }

    final List<RecordStatus> statuses = <RecordStatus>[
      for (final RecordStatus status in RecordStatus.values)
        if (facets.statuses.contains(status) ||
            filter.statuses.contains(status))
          status,
    ];
    final DateTime? from = filter.capturedFrom?.toLocal();
    final DateTime? to = filter.capturedTo?.toLocal();
    final List<Widget> fields = <Widget>[
      if (statuses.isNotEmpty)
        AppMultiChoiceField<RecordStatus>(
          key: const ValueKey<String>('records-filter-status'),
          label: Copy.recordsFilterStatus,
          options: <Choice<RecordStatus>>[
            for (final RecordStatus status in statuses)
              Choice<RecordStatus>(status, StatusStyle.of(status, colors).$3),
          ],
          value: filter.statuses,
          onChanged: (Set<RecordStatus> next) =>
              apply((RecordFilter current) => current.copyWith(statuses: next)),
        ),
      if (facets.templates.isNotEmpty)
        AppMultiChoiceField<String>(
          key: const ValueKey<String>('records-filter-template'),
          label: Copy.recordsFilterTemplate,
          options: <Choice<String>>[
            for (final ({String id, String name}) template in facets.templates)
              Choice<String>(
                template.id,
                template.name.trim().isEmpty
                    ? Copy.recordsTemplateUnnamed
                    : template.name,
              ),
          ],
          value: filter.templateIds,
          onChanged: (Set<String> next) => apply(
            (RecordFilter current) => current.copyWith(templateIds: next),
          ),
        ),
      for (final ({String key, String label, List<String> values}) level
          in facets.contextLevels)
        if (level.values.isNotEmpty)
          AppMultiChoiceField<String>(
            key: ValueKey<String>('records-filter-context-${level.key}'),
            label: level.label.trim().isEmpty ? level.key : level.label,
            options: <Choice<String>>[
              for (final String value in level.values)
                Choice<String>(value, value),
            ],
            value: filter.context[level.key] ?? const <String>{},
            onChanged: (Set<String> next) => apply(
              (RecordFilter current) => current.copyWith(
                context: _withLevel(current, level.key, next),
              ),
            ),
          ),
      AppDateField(
        key: const ValueKey<String>('records-filter-from'),
        label: Copy.recordsFilterFrom,
        value: from,
        clock: clock,
        onChanged: (DateTime? picked) => apply(
          (RecordFilter current) => picked == null
              ? current.copyWith(clearCapturedFrom: true)
              : current.copyWith(capturedFrom: _startOfDay(picked)),
        ),
      ),
      AppDateField(
        key: const ValueKey<String>('records-filter-to'),
        label: Copy.recordsFilterTo,
        value: to,
        clock: clock,
        onChanged: (DateTime? picked) => apply(
          (RecordFilter current) => picked == null
              ? current.copyWith(clearCapturedTo: true)
              : current.copyWith(capturedTo: _endOfDay(picked)),
        ),
      ),
      if (facets.operators.isNotEmpty)
        AppMultiChoiceField<String>(
          key: const ValueKey<String>('records-filter-operator'),
          label: Copy.recordsFilterOperator,
          options: <Choice<String>>[
            for (final ({String id, String label}) operator in facets.operators)
              Choice<String>(
                operator.id,
                operator.label.trim().isEmpty ? operator.id : operator.label,
              ),
          ],
          value: filter.operators,
          onChanged: (Set<String> next) => apply(
            (RecordFilter current) => current.copyWith(operators: next),
          ),
        ),
      if (facets.conditions.isNotEmpty)
        AppMultiChoiceField<String>(
          key: const ValueKey<String>('records-filter-condition'),
          label: Copy.recordsFilterCondition,
          options: <Choice<String>>[
            for (final String code in facets.conditions)
              Choice<String>(code, code),
          ],
          value: filter.conditions,
          onChanged: (Set<String> next) => apply(
            (RecordFilter current) => current.copyWith(conditions: next),
          ),
        ),
      AppMultiChoiceField<RecordFlag>(
        key: const ValueKey<String>('records-filter-flags'),
        label: Copy.recordsFilterFlags,
        options: <Choice<RecordFlag>>[
          for (final RecordFlag flag in _filterFlags)
            Choice<RecordFlag>(flag, recordFlagLabel(flag)),
        ],
        value: filter.flags,
        onChanged: (Set<RecordFlag> next) =>
            apply((RecordFilter current) => current.copyWith(flags: next)),
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < fields.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: Space.x3),
          fields[index],
        ],
      ],
    );
  }
}

/// [filter]'s context with level [key] holding [values]; an empty choice
/// drops the level.
Map<String, Set<String>> _withLevel(
  RecordFilter filter,
  String key,
  Set<String> values,
) {
  return <String, Set<String>>{
    for (final MapEntry<String, Set<String>> level in filter.context.entries)
      if (level.key != key) level.key: level.value,
    if (values.isNotEmpty) key: values,
  };
}

/// The first instant of [day]'s local calendar date, as the bound stored.
DateTime _startOfDay(DateTime day) {
  return DateTime(day.year, day.month, day.day).toUtc();
}

/// The last instant of [day]'s local calendar date, so the day it names is
/// kept whole.
DateTime _endOfDay(DateTime day) {
  return DateTime(day.year, day.month, day.day, 23, 59, 59, 999).toUtc();
}
