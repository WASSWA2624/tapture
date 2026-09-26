import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'record_edit_sheet.dart';
import 'record_thumb.dart';

/// Captured rows for [projectId], filtered by [capturedItemsQueryProvider].
/// The project home pins the search field above its scrolling body.
class CapturedItems extends ConsumerWidget {
  /// Creates the list.
  const CapturedItems({required this.projectId, super.key});

  /// Project whose records are listed.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String query = ref.watch(capturedItemsQueryProvider);
    final AsyncValue<List<ProjectRecordRow>> records = ref.watch(
      _capturedItemsProvider(projectId),
    );
    final String needle = query.trim().toLowerCase();
    final List<ProjectRecordRow> rows = records.asData?.value ?? const [];
    final List<ProjectRecordRow> visible = <ProjectRecordRow>[
      for (final ProjectRecordRow row in rows)
        if (_matches(row, needle)) row,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (visible.isEmpty && rows.isNotEmpty)
          AppEmptyState(
            icon: AppIcons.searchEmpty,
            headline: Copy.projectRecordsNoMatch(query),
            message: Copy.searchNoMatchMessage,
          )
        else if (visible.isEmpty)
          const AppEmptyState(
            icon: AppIcons.records,
            headline: Copy.projectRecordsEmptyHeadline,
            message: Copy.projectRecordsEmptyMessage,
          )
        else
          for (int index = 0; index < visible.length; index++)
            CapturedItemTile(
              projectId: projectId,
              row: visible[index],
              position: index + 1,
            ),
      ],
    );
  }
}

/// One captured record: thumbnail, title, borderless edit and delete. A
/// tap opens the record's page (FBK0000137).
class CapturedItemTile extends ConsumerWidget {
  /// Creates a row for [row] on [projectId].
  const CapturedItemTile({
    required this.projectId,
    required this.row,
    required this.position,
    super.key,
  });

  /// Project the record belongs to.
  final String projectId;

  /// Record to show.
  final ProjectRecordRow row;

  /// 1-based place in the visible list.
  final int position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecordPhotoRef? thumb = row.thumb;
    return AppListTile(
      title: projectRecordTitle(row, position: position),
      leading: thumb == null ? null : RecordThumb(photo: thumb),
      onTap: () => unawaited(
        context.push(RoutePaths.projectRecord(projectId, row.id)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconButton(
            icon: AppIcons.edit,
            outlined: false,
            tooltip: Copy.recordEdit,
            semanticLabel: Copy.recordEdit,
            onPressed: () => unawaited(showRecordEditSheet(context, row)),
          ),
          AppIconButton(
            icon: AppIcons.delete,
            outlined: false,
            tooltip: Copy.recordDelete,
            semanticLabel: Copy.recordDelete,
            onPressed: () =>
                unawaited(confirmArchiveRecord(context, ref, row.id)),
          ),
        ],
      ),
    );
  }
}

/// Query for [CapturedItems]. Ephemeral (FE-STATE-02).
final NotifierProvider<CapturedItemsQuery, String> capturedItemsQueryProvider =
    NotifierProvider<CapturedItemsQuery, String>(
      CapturedItemsQuery.new,
      retry: (int _, Object _) => null,
    );

/// Holds the captured-item search text.
final class CapturedItemsQuery extends Notifier<String> {
  @override
  String build() => '';

  /// Replaces the query.
  void set(String value) => state = value;
}

/// Record statuses the project home lists: every live record, not the
/// archived or deleted ones. Template record counts use the same set.
const List<String> capturedItemStatuses = <String>[
  'draft',
  'captured',
  'CAPTURED',
  'queued',
  'processing',
  'needsReview',
  'approved',
  'failed',
  'extracted',
];

final _capturedItemsProvider =
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

/// A record's title: its first stored value, then `Record <position>` when
/// a list gives one, then plain Record.
String projectRecordTitle(ProjectRecordRow row, {int? position}) {
  for (final ProjectRecordFieldValue field in row.fields) {
    if (field.approved.isNotEmpty) {
      return field.approved;
    }
    if (field.refined.isNotEmpty) {
      return field.refined;
    }
    if (field.raw.isNotEmpty) {
      return field.raw;
    }
  }
  return position == null
      ? Copy.recordDetailTitle
      : Copy.projectRecordPosition(position);
}

/// Asks before hiding [recordId], then archives it. True once archived.
/// The row and the record page share this confirmation.
Future<bool> confirmArchiveRecord(
  BuildContext context,
  WidgetRef ref,
  String recordId,
) async {
  final bool confirmed = await showAppConfirm(
    context,
    title: Copy.recordDelete,
    message: Copy.recordArchiveMessage,
    confirmLabel: Copy.recordDelete,
    destructive: true,
  );
  if (!confirmed) {
    return false;
  }
  final Result<void> archived = await ref
      .read(projectRepositoryProvider)
      .archiveRecord(recordId);
  return archived is Success<void>;
}
