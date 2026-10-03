import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'captured_record_tile.dart';
import 'captured_records_query.dart';
import 'project_record_filter.dart';

export 'captured_record_tile.dart';
export 'captured_records_query.dart';

/// Captured rows for [projectId], filtered by [capturedItemsQueryProvider].
/// The project home pins the search field above its scrolling body.
class CapturedRecords extends ConsumerWidget {
  /// Creates the list.
  const CapturedRecords({required this.projectId, super.key});

  /// Project whose records are listed.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String query = ref.watch(capturedItemsQueryProvider);
    final Set<RecordStatus> statuses = ref.watch(projectRecordFilterProvider);
    final AsyncValue<List<ProjectRecordRow>> records = ref.watch(
      capturedItemsProvider(projectId),
    );
    final String needle = query.trim().toLowerCase();
    final List<ProjectRecordRow> rows = records.asData?.value ?? const [];
    final List<ProjectRecordRow> visible = <ProjectRecordRow>[
      for (final ProjectRecordRow row in rows)
        if (_matches(row, needle) && ProjectRecordFilter.matches(row, statuses))
          row,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (visible.isEmpty && rows.isNotEmpty)
          AppEmptyState(
            icon: AppIcons.searchEmpty,
            headline: localCopy.projectRecordsNoMatch(query),
            message: statuses.isEmpty
                ? localCopy.searchNoMatchMessage
                : localCopy.searchFilterNoMatchMessage,
          )
        else if (visible.isEmpty)
          AppEmptyState(
            icon: AppIcons.records,
            headline: localCopy.projectRecordsEmptyHeadline,
            message: localCopy.projectRecordsEmptyMessage,
          )
        else
          for (int index = 0; index < visible.length; index++)
            CapturedRecordTile(
              projectId: projectId,
              row: visible[index],
              position: index + 1,
            ),
      ],
    );
  }
}

/// Query for [CapturedRecords]. Ephemeral (FE-STATE-02).
final NotifierProvider<CapturedRecordsQuery, String>
capturedItemsQueryProvider = NotifierProvider<CapturedRecordsQuery, String>(
  CapturedRecordsQuery.new,
  retry: (int _, Object _) => null,
);

/// Record statuses the project home lists: every live record, not the
/// archived or deleted ones. Template record counts use the same set.
final List<String> capturedItemStatuses = List<String>.unmodifiable(<String>[
  for (final RecordStatus status in RecordStatus.values)
    if (status != RecordStatus.archived && status != RecordStatus.deleted)
      status.stored,
]);

/// The live records a project's home lists, before its search and filters.
final capturedItemsProvider =
    StreamProvider.family<List<ProjectRecordRow>, String>((
      Ref ref,
      String projectId,
    ) {
      return ref
          .watch(projectRepositoryProvider)
          .watchRecords(projectId, statuses: capturedItemStatuses);
    }, retry: (int _, Object _) => null);

bool _matches(ProjectRecordRow row, String needle) {
  if (needle.isEmpty) {
    return true;
  }
  for (final ProjectRecordFieldValue field in row.fields) {
    if (field.raw.toLowerCase().contains(needle) ||
        field.refined.toLowerCase().contains(needle) ||
        field.approved.toLowerCase().contains(needle)) {
      return true;
    }
  }
  return projectRecordTitle(row, position: 1).toLowerCase().contains(needle);
}
