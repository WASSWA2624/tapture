import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/record_facets.dart';
import '../domain/record_filter.dart';
import '../domain/record_flag.dart';
import '../domain/record_photo.dart';
import '../domain/record_sort.dart';
import '../domain/record_summary.dart';
import 'record_delete_action.dart';
import 'record_selection.dart';
import 'records_filter_sheet.dart';
import 'records_list_controller.dart';
import 'records_page_providers.dart';
import 'records_sort_menu.dart';

/// One project's records: search, filters as removable chips, the sort, and
/// a virtualised list that holds only the pages on screen (task 014 step 2,
/// FE-PERF-03).
///
/// Each row shows number, name, identifier, context and status, with the
/// first photo's cached thumbnail (FE-CONS-06). Tap opens the record;
/// long-press ticks it for bulk actions, and while any record is ticked a
/// tap ticks too (FE-CONS-10).
///
/// [pane] is the narrow list beside a record on expanded layouts: tighter
/// rows without their edit and delete controls, the open record
/// ([currentRecordId]) marked (FE-RESP-05).
final class RecordsListView extends ConsumerWidget {
  /// Creates the list of [projectId]'s records.
  const RecordsListView({
    required this.projectId,
    this.pane = false,
    this.currentRecordId,
    this.onOpen,
    super.key,
  });

  /// The project whose records are listed.
  final String projectId;

  /// Whether this is the compact list pane beside a record.
  final bool pane;

  /// The record shown beside the list, marked as current. Null marks none.
  final String? currentRecordId;

  /// Opens a record by id. Null pushes the record's page in its project.
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecordsListCriteria criteria = ref.watch(
      recordsListControllerProvider(projectId),
    );
    final RecordsListController controller = ref.read(
      recordsListControllerProvider(projectId).notifier,
    );
    final RecordFilter filter = criteria.filter;
    final AsyncValue<int> count = ref.watch(
      recordsCountProvider((projectId: projectId, filter: filter)),
    );
    final double gutter = pane ? Space.x3 : AppPage.gutter(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.x2, gutter, Space.x2),
          child: AppSearchField(
            key: const ValueKey<String>('records-search'),
            hint: Copy.recordsSearchHint,
            text: filter.search,
            onChanged: controller.setSearch,
            onFilter: () => unawaited(
              RecordsFilterSheet.show(context, projectId: projectId),
            ),
            activeFilterCount: filter.activeCount,
            resultCount: filter.isEmpty ? null : count.asData?.value,
            afterMic: RecordsSortMenu(projectId: projectId),
          ),
        ),
        if (filter.activeCount > 0)
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, Space.x0, gutter, Space.x2),
            child: _ActiveFilters(projectId: projectId, filter: filter),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget body = AsyncValueView<int>(
                value: count,
                onRetry: () => ref.invalidate(
                  recordsCountProvider((projectId: projectId, filter: filter)),
                ),
                isEmpty: (int total) => total == 0,
                empty: () => _EmptyList(
                  projectId: projectId,
                  filter: filter,
                  controller: controller,
                ),
                loadingCount: _rowsThatFit(constraints.maxHeight),
                data: (int total) => _RecordRows(
                  key: ValueKey<RecordsListCriteria>(criteria),
                  projectId: projectId,
                  criteria: criteria,
                  total: total,
                  pane: pane,
                  currentRecordId: currentRecordId,
                  onOpen: onOpen,
                ),
              );
              // The failure panel scrolls, so it is whole on a short window
              // and at 200 percent text (FE-RESP-06).
              return count.hasError && !count.hasValue
                  ? SingleChildScrollView(child: body)
                  : body;
            },
          ),
        ),
      ],
    );
  }
}

/// How many skeleton rows fill [height] while the count loads, so the
/// placeholder is one screen's worth and never overflows a short window.
int _rowsThatFit(double height) {
  if (!height.isFinite) {
    return 1;
  }
  return (height / (Sizes.minTapTarget + Space.x6)).floor().clamp(0, 12);
}

/// The virtualised rows. Every row has the prototype's height, so the list
/// jumps to any of thousands of rows without building the ones between.
class _RecordRows extends StatelessWidget {
  const _RecordRows({
    required this.projectId,
    required this.criteria,
    required this.total,
    required this.pane,
    required this.currentRecordId,
    required this.onOpen,
    super.key,
  });

  final String projectId;
  final RecordsListCriteria criteria;
  final int total;
  final bool pane;
  final String? currentRecordId;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.builder(
        key: const ValueKey<String>('records-list'),
        itemCount: total,
        prototypeItem: _PrototypeRow(pane: pane),
        itemBuilder: (BuildContext context, int index) {
          return _RecordRow(
            projectId: projectId,
            criteria: criteria,
            index: index,
            pane: pane,
            currentRecordId: currentRecordId,
            onOpen: onOpen,
          );
        },
      ),
    );
  }
}

/// Row [index] of the list, read from the page it falls in. A skeleton
/// while that page loads; the page's failure, once, on its first row.
class _RecordRow extends ConsumerWidget {
  const _RecordRow({
    required this.projectId,
    required this.criteria,
    required this.index,
    required this.pane,
    required this.currentRecordId,
    required this.onOpen,
  });

  final String projectId;
  final RecordsListCriteria criteria;
  final int index;
  final bool pane;
  final String? currentRecordId;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int size = AppConstants.lists.pageSize;
    final ({String projectId, RecordFilter filter, RecordSort sort, int page})
    query = (
      projectId: projectId,
      filter: criteria.filter,
      sort: criteria.sort,
      page: index ~/ size,
    );
    final AsyncValue<List<RecordSummary>> page = ref.watch(
      recordsPageProvider(query),
    );
    final int offset = index % size;
    // A page being read again keeps showing what it held.
    final List<RecordSummary>? rows = page.value;
    if (rows != null && offset < rows.length) {
      return _SummaryRow(
        summary: rows[offset],
        projectId: projectId,
        pane: pane,
        current: rows[offset].id == currentRecordId,
        onOpen: onOpen,
      );
    }
    final Object? error = page.error;
    if (error != null) {
      return _PageFailedRow(
        failure: Failure.from(error),
        pane: pane,
        onRetry: () => ref.invalidate(recordsPageProvider(query)),
      );
    }
    return _SkeletonRow(pane: pane);
  }
}

/// A row whose page could not be read: why, and a tap to read it again.
class _PageFailedRow extends StatelessWidget {
  const _PageFailedRow({
    required this.failure,
    required this.pane,
    required this.onRetry,
  });

  final Failure failure;
  final bool pane;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: failure.message,
      subtitle: failure.recoveryAction ?? Copy.tryAgain,
      leading: Icon(
        AppIcons.error,
        color: context.colors.danger,
        size: Space.x6,
      ),
      dense: pane,
      onTap: onRetry,
    );
  }
}

/// One record as a list row.
class _SummaryRow extends ConsumerWidget {
  const _SummaryRow({
    required this.summary,
    required this.projectId,
    required this.pane,
    required this.current,
    required this.onOpen,
  });

  final RecordSummary summary;
  final String projectId;
  final bool pane;
  final bool current;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String id = summary.id;
    final bool selected = ref.watch(
      recordSelectionProvider(
        projectId,
      ).select((Set<String> ids) => ids.contains(id)),
    );
    final bool selecting = ref.watch(
      recordSelectionProvider(
        projectId,
      ).select((Set<String> ids) => ids.isNotEmpty),
    );
    final RecordPhoto? thumb = summary.thumb;
    final String subtitle = Copy.recordsRowSubtitle(
      number: summary.number,
      identifier: summary.identifier,
      context: summary.contextLabel,
    );
    void toggle() {
      ref.read(recordSelectionProvider(projectId).notifier).toggle(id);
    }

    return AppListTile(
      key: ValueKey<String>('record-row-$id'),
      title: summary.name.trim().isNotEmpty
          ? summary.name
          : Copy.recordsUntitled(summary.number),
      subtitle: subtitle.isEmpty ? null : subtitle,
      leading: thumb == null
          ? null
          : RecordThumb(
              sha256: thumb.sha256,
              storagePath: thumb.storagePath,
              quarterTurns: thumb.quarterTurns,
              hasCaption: thumb.hasCaption,
            ),
      status: AppStatusPill.badge(status: summary.status),
      dense: pane,
      selected: selected,
      current: current,
      onTap: selecting ? toggle : () => _open(context, id),
      onLongPress: toggle,
      trailing: pane || selecting
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIconButton(
                  key: ValueKey<String>('record-edit-$id'),
                  icon: AppIcons.edit,
                  tooltip: Copy.recordEdit,
                  semanticLabel: Copy.recordEdit,
                  // The capture page edits photos and captions; values are
                  // edited from the record's page.
                  onPressed: () => unawaited(
                    context.push(
                      RoutePaths.projectRecordEdit(summary.projectId, id),
                    ),
                  ),
                ),
                const SizedBox(width: Space.x1),
                RecordDeleteAction(
                  key: ValueKey<String>('record-delete-$id'),
                  ids: <String>[id],
                ),
              ],
            ),
    );
  }

  void _open(BuildContext context, String id) {
    final ValueChanged<String>? open = onOpen;
    if (open != null) {
      open(id);
      return;
    }
    unawaited(context.push(RoutePaths.projectRecord(summary.projectId, id)));
  }
}

/// What every row measures against: the tallest a row can be, with every
/// slot filled. Laid out once, never shown or read.
class _PrototypeRow extends StatelessWidget {
  const _PrototypeRow({required this.pane});

  final bool pane;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: Copy.recordsUntitled(0),
      subtitle: Copy.recordsRowSubtitle(number: 0),
      leading: const SizedBox.square(dimension: Sizes.minTapTarget),
      status: const AppStatusPill.badge(status: RecordStatus.needsReview),
      dense: pane,
      trailing: pane
          ? null
          : const SizedBox(
              width: Sizes.minTapTarget * 2 + Space.x1,
              height: Sizes.minTapTarget,
            ),
    );
  }
}

/// A row whose page is still loading: the row's shape, no content.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.pane});

  final bool pane;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Semantics(
      label: Copy.loading,
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Space.x4,
            vertical: pane ? Space.x1 : Space.x3,
          ),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: Sizes.minTapTarget,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: SizedBox(
                  height: Space.x4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The active filters as chips: each removes its one value, and a last chip
/// turns them all off in one tap (task 037).
class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters({required this.projectId, required this.filter});

  final String projectId;
  final RecordFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    void apply(RecordFilter next) => controller.applyFilter(next);

    return AppChipRow(
      key: const ValueKey<String>('records-active-filters'),
      scrollable: true,
      chips: <AppChip>[
        for (final RecordStatus status in RecordStatus.values)
          if (filter.statuses.contains(status))
            AppChip(
              key: ValueKey<String>('records-chip-status-${status.stored}'),
              label: StatusStyle.of(status, colors).$3,
              onDismiss: () => apply(filter.withoutStatus(status)),
            ),
        for (final String id in _sorted(filter.templateIds))
          AppChip(
            key: ValueKey<String>('records-chip-template-$id'),
            label: Copy.recordsChipTemplate(_templateName(facets, id)),
            onDismiss: () => apply(filter.withoutTemplate(id)),
          ),
        for (final String key in _sorted(filter.context.keys))
          for (final String value in _sorted(filter.context[key]!))
            AppChip(
              key: ValueKey<String>('records-chip-context-$key-$value'),
              label: Copy.recordsChipContext(_levelLabel(facets, key), value),
              onDismiss: () => apply(filter.withoutContextValue(key, value)),
            ),
        if (filter.hasCapturedRange)
          AppChip(
            key: const ValueKey<String>('records-chip-dates'),
            label: Copy.recordsChipDates(
              from: filter.capturedFrom?.toLocal(),
              to: filter.capturedTo?.toLocal(),
              locale: locale,
            ),
            onDismiss: () => apply(filter.withoutCapturedRange()),
          ),
        for (final String id in _sorted(filter.operators))
          AppChip(
            key: ValueKey<String>('records-chip-operator-$id'),
            label: Copy.recordsChipOperator(_operatorLabel(facets, id)),
            onDismiss: () => apply(filter.withoutOperator(id)),
          ),
        for (final String code in _sorted(filter.conditions))
          AppChip(
            key: ValueKey<String>('records-chip-condition-$code'),
            label: Copy.recordsChipCondition(code),
            onDismiss: () => apply(filter.withoutCondition(code)),
          ),
        for (final RecordFlag flag in RecordFlag.values)
          if (filter.flags.contains(flag))
            AppChip(
              key: ValueKey<String>('records-chip-flag-${flag.stored}'),
              label: recordFlagLabel(flag),
              onDismiss: () => apply(filter.withoutFlag(flag)),
            ),
        AppChip(
          key: const ValueKey<String>('records-clear-filters'),
          label: Copy.searchClearFilters,
          icon: AppIcons.clear,
          onTap: controller.clearFilters,
        ),
      ],
    );
  }
}

/// No records at all, or none that match: each names the next action and
/// offers it (FE-SIMP-11).
class _EmptyList extends StatelessWidget {
  const _EmptyList({
    required this.projectId,
    required this.filter,
    required this.controller,
  });

  final String projectId;
  final RecordFilter filter;
  final RecordsListController controller;

  @override
  Widget build(BuildContext context) {
    final bool searching = filter.search.trim().isNotEmpty;
    final bool filtering = filter.activeCount > 0;
    final Widget state = !searching && !filtering
        ? AppEmptyState(
            key: const ValueKey<String>('records-empty'),
            icon: AppIcons.records,
            headline: Copy.recordsEmptyHeadline,
            message: Copy.recordsEmptyMessage,
            actionLabel: Copy.recordsEmptyAction,
            onAction: () =>
                unawaited(context.push(RoutePaths.projectCapture(projectId))),
          )
        : AppEmptyState(
            key: const ValueKey<String>('records-no-match'),
            icon: AppIcons.searchEmpty,
            headline: Copy.recordsNoMatch(filter.search),
            message: filtering
                ? Copy.searchFilterNoMatchMessage
                : Copy.searchNoMatchMessage,
            actionLabel: searching && filtering
                ? Copy.recordsClearAll
                : filtering
                ? Copy.searchClearFilters
                : Copy.recordsClearSearch,
            onAction: controller.clearAll,
          );
    return SingleChildScrollView(child: state);
  }
}

String _templateName(RecordFacets facets, String id) {
  for (final ({String id, String name}) template in facets.templates) {
    if (template.id == id && template.name.trim().isNotEmpty) {
      return template.name;
    }
  }
  return Copy.recordsTemplateUnnamed;
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
