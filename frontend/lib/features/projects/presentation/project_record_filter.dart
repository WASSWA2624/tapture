import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/project_repository.dart';

/// The record statuses a project's records list is narrowed to. Empty lists
/// every status. Ephemeral, like the list's query (FE-STATE-02).
final class ProjectRecordFilter extends Notifier<Set<RecordStatus>> {
  @override
  Set<RecordStatus> build() => const <RecordStatus>{};

  /// Lists only records in [statuses].
  void set(Set<RecordStatus> statuses) {
    state = Set<RecordStatus>.unmodifiable(statuses);
  }

  /// Lists every status again.
  void clear() => state = const <RecordStatus>{};

  /// The lifecycle status a stored [raw] status names, whatever its case or
  /// separators (`CAPTURED`, `needs_review`), or null for one outside the
  /// set.
  static RecordStatus? statusOf(String raw) {
    final String folded = _fold(raw);
    for (final RecordStatus status in RecordStatus.values) {
      if (_fold(status.name) == folded) {
        return status;
      }
    }
    return null;
  }

  /// Whether [row] is listed under [statuses].
  static bool matches(ProjectRecordRow row, Set<RecordStatus> statuses) {
    return statuses.isEmpty || statuses.contains(statusOf(row.status));
  }
}

String _fold(String value) => value.replaceAll('_', '').trim().toLowerCase();

/// The chosen record statuses (FE-STATE-02).
final NotifierProvider<ProjectRecordFilter, Set<RecordStatus>>
projectRecordFilterProvider =
    NotifierProvider<ProjectRecordFilter, Set<RecordStatus>>(
      ProjectRecordFilter.new,
      retry: (int _, Object _) => null,
    );

/// Opens a project's records filters over the statuses [rows] are in, each
/// named as its status pill names it (FE-CONS-07).
Future<void> showProjectRecordFilters(
  BuildContext context,
  WidgetRef ref,
  List<ProjectRecordRow> rows,
) {
  final Set<RecordStatus> present = <RecordStatus>{
    for (final ProjectRecordRow row in rows)
      ?ProjectRecordFilter.statusOf(row.status),
  };
  final List<RecordStatus> statuses = <RecordStatus>[
    for (final RecordStatus status in RecordStatus.values)
      if (present.contains(status)) status,
  ];
  return showAppFilterSheet(
    context,
    title: Copy.projectRecordFiltersTitle,
    onClear: ref.read(projectRecordFilterProvider.notifier).clear,
    facets: (BuildContext _) => _StatusFacet(statuses: statuses),
  );
}

class _StatusFacet extends ConsumerWidget {
  const _StatusFacet({required this.statuses});

  final List<RecordStatus> statuses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    return AppMultiChoiceField<RecordStatus>(
      key: const ValueKey<String>('record-status-filter'),
      label: Copy.projectRecordStatusFilter,
      options: <Choice<RecordStatus>>[
        for (final RecordStatus status in statuses)
          Choice<RecordStatus>(status, StatusStyle.of(status, colors).$3),
      ],
      value: ref.watch(projectRecordFilterProvider),
      onChanged: ref.read(projectRecordFilterProvider.notifier).set,
    );
  }
}
