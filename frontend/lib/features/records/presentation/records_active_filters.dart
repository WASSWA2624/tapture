import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';

import '../domain/record_facets.dart';
import '../domain/record_filter.dart';
import '../domain/record_flag.dart';
import 'records_filter_sheet.dart';
import 'records_list_controller.dart';
import 'records_page_providers.dart';

/// A records list's active filters as removable chips (task 014 step 2,
/// task 037): one per chosen value, each removing only that value, then a
/// chip that turns every filter off in one tap. The search is not a chip;
/// its field shows it.
final class RecordsActiveFilters extends ConsumerWidget {
  /// Creates the chips of [filter] on [projectId]'s list.
  const RecordsActiveFilters({
    required this.projectId,
    required this.filter,
    super.key,
  });

  /// The project whose list is filtered.
  final String projectId;

  /// The filter the chips show.
  final RecordFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordsListController controller = ref.read(
      recordsListControllerProvider(projectId).notifier,
    );
    final bool needsNames =
        filter.templateIds.isNotEmpty ||
        filter.operators.isNotEmpty ||
        filter.context.isNotEmpty;
    final RecordFacets facets = needsNames
        ? ref.watch(recordsFacetsProvider(projectId)).asData?.value ??
              RecordFacets.empty
        : RecordFacets.empty;
    final AppColors colors = context.colors;
    final String locale = Localizations.localeOf(context).toString();
    void apply(RecordFilter Function(RecordFilter current) change) {
      controller.updateFilter(change);
    }

    return AppChipRow(
      key: const ValueKey<String>('records-active-filters'),
      scrollable: true,
      chips: <AppChip>[
        for (final RecordStatus status in RecordStatus.values)
          if (filter.statuses.contains(status))
            AppChip(
              key: ValueKey<String>('records-chip-status-${status.stored}'),
              label: StatusStyle.of(status, colors).$3,
              onDismiss: () => apply(
                (RecordFilter current) => current.withoutStatus(status),
              ),
            ),
        for (final String id in _sorted(filter.templateIds))
          AppChip(
            key: ValueKey<String>('records-chip-template-$id'),
            label: localCopy.recordsChipTemplate(
              _templateName(facets, id, localizedCopy: Copy.of(context)),
            ),
            onDismiss: () =>
                apply((RecordFilter current) => current.withoutTemplate(id)),
          ),
        for (final String key in _sorted(filter.context.keys))
          for (final String value in _sorted(filter.context[key]!))
            AppChip(
              key: ValueKey<String>('records-chip-context-$key-$value'),
              label: localCopy.recordsChipContext(
                _levelLabel(facets, key),
                value,
              ),
              onDismiss: () => apply(
                (RecordFilter current) =>
                    current.withoutContextValue(key, value),
              ),
            ),
        if (filter.hasCapturedRange)
          AppChip(
            key: const ValueKey<String>('records-chip-dates'),
            label: localCopy.recordsChipDates(
              from: filter.capturedFrom?.toLocal(),
              to: filter.capturedTo?.toLocal(),
              locale: locale,
            ),
            onDismiss: () =>
                apply((RecordFilter current) => current.withoutCapturedRange()),
          ),
        for (final String id in _sorted(filter.operators))
          AppChip(
            key: ValueKey<String>('records-chip-operator-$id'),
            label: localCopy.recordsChipOperator(_operatorLabel(facets, id)),
            onDismiss: () =>
                apply((RecordFilter current) => current.withoutOperator(id)),
          ),
        for (final String code in _sorted(filter.conditions))
          AppChip(
            key: ValueKey<String>('records-chip-condition-$code'),
            label: localCopy.recordsChipCondition(code),
            onDismiss: () =>
                apply((RecordFilter current) => current.withoutCondition(code)),
          ),
        for (final RecordFlag flag in RecordFlag.values)
          if (filter.flags.contains(flag))
            AppChip(
              key: ValueKey<String>('records-chip-flag-${flag.stored}'),
              label: recordFlagLabel(flag),
              onDismiss: () =>
                  apply((RecordFilter current) => current.withoutFlag(flag)),
            ),
        AppChip(
          key: const ValueKey<String>('records-clear-filters'),
          label: localCopy.searchClearFilters,
          icon: AppIcons.clear,
          onTap: controller.clearFilters,
        ),
      ],
    );
  }
}

String _templateName(
  RecordFacets facets,
  String id, {
  LocalizedCopy? localizedCopy,
}) {
  for (final ({String id, String name}) template in facets.templates) {
    if (template.id == id && template.name.trim().isNotEmpty) {
      return template.name;
    }
  }
  return (localizedCopy ?? Copy.english).recordsTemplateUnnamed;
}

String _levelLabel(RecordFacets facets, String key) {
  for (final ({String key, String label, List<String> values}) level
      in facets.contextLevels) {
    if (level.key == key && level.label.trim().isNotEmpty) {
      return level.label;
    }
  }
  return key;
}

String _operatorLabel(RecordFacets facets, String id) {
  for (final ({String id, String label}) operator in facets.operators) {
    if (operator.id == id && operator.label.trim().isNotEmpty) {
      return operator.label;
    }
  }
  return id;
}

List<String> _sorted(Iterable<String> values) => values.toList()..sort();
