import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;

/// Search plus captured rows for [projectId].
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
        AppSearchField(
          hint: Copy.search,
          text: query,
          onChanged: (String text) {
            ref.read(capturedItemsQueryProvider.notifier).set(text);
          },
        ),
        if (visible.isEmpty)
          const AppEmptyState(
            icon: Icons.photo_library_outlined,
            headline: Copy.projectRecordsEmptyHeadline,
            message: Copy.projectRecordsEmptyMessage,
          )
        else
          for (int index = 0; index < visible.length; index++)
            CapturedItemTile(row: visible[index], position: index + 1),
      ],
    );
  }
}

/// One captured record: thumbnail, title, borderless edit and delete.
class CapturedItemTile extends ConsumerWidget {
  /// Creates a row for [row].
  const CapturedItemTile({
    required this.row,
    required this.position,
    super.key,
  });

  /// Record to show.
  final ProjectRecordRow row;

  /// 1-based place in the visible list.
  final int position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? thumb = row.thumbPath;
    return AppListTile(
      title: _title(row, position),
      leading: thumb == null || thumb.isEmpty
          ? null
          : AppPhotoThumb(
              photo: PhotoAsset(sha256: row.id, thumbPath: thumb),
              size: Space.x12,
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconButton(
            icon: Icons.edit_outlined,
            outlined: false,
            tooltip: Copy.recordEdit,
            semanticLabel: Copy.recordEdit,
            onPressed: () => unawaited(_edit(context, ref, row)),
          ),
          AppIconButton(
            icon: Icons.delete_outline,
            outlined: false,
            tooltip: Copy.recordDelete,
            semanticLabel: Copy.recordDelete,
            onPressed: () => unawaited(_archive(context, ref, row)),
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
  return _title(row, 1).toLowerCase().contains(needle);
}

String _title(ProjectRecordRow row, int position) {
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
  return Copy.projectRecordPosition(position);
}

Future<void> _edit(
  BuildContext context,
  WidgetRef ref,
  ProjectRecordRow row,
) async {
  final Map<String, TextEditingController> controllers =
      <String, TextEditingController>{
        for (final ProjectRecordFieldValue field in row.fields)
          field.fieldKey: TextEditingController(
            text: field.refined.isNotEmpty ? field.refined : field.raw,
          ),
      };
  final bool? saved = await showAppSheet<bool>(
    context,
    title: Copy.recordEdit,
    builder: (BuildContext sheetContext) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final ProjectRecordFieldValue field in row.fields)
            AppTextField(
              label: field.fieldKey,
              controller: controllers[field.fieldKey]!,
            ),
          AppIconButton(
            icon: Icons.check,
            outlined: false,
            tooltip: Copy.save,
            semanticLabel: Copy.save,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
        ],
      );
    },
  );
  if (saved != true) {
    for (final TextEditingController controller in controllers.values) {
      controller.dispose();
    }
    return;
  }
  final ProjectRepository repository = ref.read(projectRepositoryProvider);
  for (final ProjectRecordFieldValue field in row.fields) {
    final String text = controllers[field.fieldKey]?.text ?? '';
    if (text == field.raw && field.refined.isEmpty) {
      continue;
    }
    await repository.refineRecordField(
      recordId: row.id,
      fieldKey: field.fieldKey,
      value: text,
    );
  }
  for (final TextEditingController controller in controllers.values) {
    controller.dispose();
  }
}

Future<void> _archive(
  BuildContext context,
  WidgetRef ref,
  ProjectRecordRow row,
) async {
  final bool confirmed = await showAppConfirm(
    context,
    title: Copy.recordDelete,
    message: Copy.recordArchiveMessage,
    confirmLabel: Copy.recordDelete,
    destructive: true,
  );
  if (!confirmed) {
    return;
  }
  await ref.read(projectRepositoryProvider).archiveRecord(row.id);
}
