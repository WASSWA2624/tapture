import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/record_filter.dart';
import '../domain/record_sort.dart';
import 'record_bulk_actions.dart';
import 'records_active_filters.dart';
import 'records_filter_sheet.dart';
import 'records_list_controller.dart';
import 'records_list_row.dart';
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
            child: RecordsActiveFilters(projectId: projectId, filter: filter),
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
                  onShown: (String id) {
                    ref
                        .read(
                          _shownProvider(
                            _shownKey(projectId, criteria),
                          ).notifier,
                        )
                        .note(id);
                  },
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
        _BulkBar(projectId: projectId, criteria: criteria),
      ],
    );
  }
}

/// The selection bar. It watches which rows have been on screen, so noting
/// one does not rebuild the list.
class _BulkBar extends ConsumerWidget {
  const _BulkBar({required this.projectId, required this.criteria});

  final String projectId;
  final RecordsListCriteria criteria;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> shown = ref
        .watch(_shownProvider(_shownKey(projectId, criteria)))
        .toList(growable: false);
    return RecordBulkActions(projectId: projectId, selectable: shown);
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
    required this.onShown,
    super.key,
  });

  final String projectId;
  final RecordsListCriteria criteria;
  final int total;
  final bool pane;
  final String? currentRecordId;
  final ValueChanged<String>? onOpen;
  final ValueChanged<String> onShown;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.builder(
        key: const ValueKey<String>('records-list'),
        itemCount: total,
        prototypeItem: RecordsListRow.prototype(pane: pane),
        itemBuilder: (BuildContext context, int index) {
          return RecordsListRow(
            projectId: projectId,
            criteria: criteria,
            index: index,
            pane: pane,
            currentRecordId: currentRecordId,
            onOpen: onOpen,
            onShown: onShown,
          );
        },
      ),
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

/// Which rows of one filtered list have been on screen. Select all ticks
/// these, and a new filter or order starts empty.
typedef _ShownKey = ({String projectId, RecordFilter filter, RecordSort sort});

_ShownKey _shownKey(String projectId, RecordsListCriteria criteria) {
  return (projectId: projectId, filter: criteria.filter, sort: criteria.sort);
}

final _shownProvider = NotifierProvider.autoDispose
    .family<_ShownRecords, Set<String>, _ShownKey>(
      _ShownRecords.new,
      retry: (int _, Object _) => null,
    );

/// Record ids a list has built, in the order they first appeared.
class _ShownRecords extends Notifier<Set<String>> {
  _ShownRecords(this._key);

  // ignore: unused_field, the family key isolates one filter's shown rows
  final _ShownKey _key;

  @override
  Set<String> build() => const <String>{};

  /// Remembers [id]. An id already remembered changes nothing.
  void note(String id) {
    if (state.contains(id)) {
      return;
    }
    state = Set<String>.unmodifiable(<String>{...state, id});
  }
}
