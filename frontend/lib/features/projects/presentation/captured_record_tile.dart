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
import 'package:tapture/core/widgets/record_thumb.dart';
import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;

/// One captured record: thumbnail, title, borderless edit and delete. A
/// tap opens the record's page (FBK0000137).
class CapturedRecordTile extends ConsumerWidget {
  /// Creates a row for [row] on [projectId].
  const CapturedRecordTile({
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
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordPhotoRef? thumb = row.thumb;
    return AppListTile(
      title: projectRecordTitle(
        row,
        position: position,
        localizedCopy: Copy.of(context),
      ),
      leading: thumb == null
          ? null
          : RecordThumb(
              sha256: thumb.sha256,
              storagePath: thumb.storagePath,
              quarterTurns: thumb.quarterTurns,
            ),
      onTap: () =>
          unawaited(context.push(RoutePaths.projectRecord(projectId, row.id))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconButton(
            icon: AppIcons.edit,
            outlined: false,
            tooltip: localCopy.recordEdit,
            semanticLabel: localCopy.recordEdit,
            // Edit opens the record on the capture page; field values are
            // edited from the record's page (FBK0000148).
            onPressed: () => unawaited(
              context.push(RoutePaths.projectRecordEdit(projectId, row.id)),
            ),
          ),
          AppIconButton(
            icon: AppIcons.delete,
            outlined: false,
            tooltip: localCopy.recordDelete,
            semanticLabel: localCopy.recordDelete,
            onPressed: () =>
                unawaited(confirmArchiveRecord(context, ref, row.id)),
          ),
        ],
      ),
    );
  }
}

/// A record's title: its first stored value, then `Record <position>` when
/// a list gives one, then plain Record.
String projectRecordTitle(
  ProjectRecordRow row, {
  int? position,
  LocalizedCopy? localizedCopy,
}) {
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
      ? (localizedCopy ?? Copy.english).recordDetailTitle
      : (localizedCopy ?? Copy.english).projectRecordPosition(position);
}

/// Asks before hiding [recordId], then archives it. True once archived.
/// The row and the record page share this confirmation.
Future<bool> confirmArchiveRecord(
  BuildContext context,
  WidgetRef ref,
  String recordId,
) async {
  final LocalizedCopy localCopy = Copy.of(context);

  final bool confirmed = await showAppConfirm(
    context,
    title: localCopy.recordDelete,
    message: localCopy.recordArchiveMessage,
    confirmLabel: localCopy.recordDelete,
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
