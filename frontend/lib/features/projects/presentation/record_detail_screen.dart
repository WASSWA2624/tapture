import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'captured_items.dart';
import 'record_edit_sheet.dart';
import 'record_thumb.dart';

/// One record: its photos, caption, field values, audio and capture time,
/// with its field editor and delete in the menu (FBK0000137).
final class RecordDetailScreen extends ConsumerWidget {
  /// Creates the page for [recordId] on [projectId].
  const RecordDetailScreen({
    required this.projectId,
    required this.recordId,
    super.key,
  });

  /// Project the record belongs to.
  final String projectId;

  /// Record shown.
  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProjectRecordDetail?> value = ref.watch(
      recordDetailProvider(recordId),
    );
    final ProjectRecordDetail? detail = value.asData?.value;
    return AppPage(
      key: const ValueKey<String>('route-record'),
      title: detail == null
          ? Copy.recordDetailTitle
          : projectRecordTitle(detail.row),
      overflow: detail == null
          ? const <AppOverflowAction>[]
          : <AppOverflowAction>[
              AppOverflowAction(
                label: Copy.recordEditFields,
                icon: AppIcons.fields,
                onTap: () =>
                    unawaited(showRecordEditSheet(context, detail.row)),
              ),
              AppOverflowAction(
                label: Copy.recordDelete,
                icon: AppIcons.delete,
                onTap: () => unawaited(_delete(context, ref)),
              ),
            ],
      body: AsyncValueView<ProjectRecordDetail?>(
        value: value,
        isEmpty: (ProjectRecordDetail? loaded) => loaded == null,
        empty: () => const AppEmptyState(
          icon: AppIcons.records,
          headline: Copy.recordGoneHeadline,
          message: Copy.recordGoneMessage,
        ),
        onRetry: () => ref.invalidate(recordDetailProvider(recordId)),
        data: (ProjectRecordDetail? loaded) => _RecordBody(detail: loaded!),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool archived = await confirmArchiveRecord(context, ref, recordId);
    if (archived && context.mounted && context.canPop()) {
      context.pop();
    }
  }
}

/// A live record for its page. Null once it is archived or gone.
final recordDetailProvider = StreamProvider.autoDispose
    .family<ProjectRecordDetail?, String>((Ref ref, String recordId) {
      return ref.watch(projectRepositoryProvider).watchRecord(recordId);
    }, retry: (int _, Object _) => null);

class _RecordBody extends ConsumerWidget {
  const _RecordBody({required this.detail});

  final ProjectRecordDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TemplateDef? template = ref
        .watch(recordTemplateProvider(detail.row.templateId))
        .asData
        ?.value;
    final List<RecordEditEntry> entries = recordEditEntries(
      template: template,
      row: detail.row,
    );
    final String locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (detail.photos.isNotEmpty) ...<Widget>[
          const AppSectionHeader(title: Copy.capturePhotosSection),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: <Widget>[
              for (final RecordPhotoCaption photo in detail.photos)
                RecordThumb(
                  photo: photo.photo,
                  size: Space.x12 * 2,
                  hasCaption: photo.caption.isNotEmpty,
                ),
            ],
          ),
          const SizedBox(height: Space.x4),
        ],
        const AppSectionHeader(title: Copy.captureRecordCaption),
        Text(
          detail.caption.isEmpty ? Copy.recordNoCaption : detail.caption,
          style: AppText.body,
        ),
        const SizedBox(height: Space.x4),
        const AppSectionHeader(title: Copy.recordSectionFields),
        if (entries.isEmpty)
          const Text(Copy.recordEditNoFieldsHeadline, style: AppText.body)
        else
          for (final RecordEditEntry entry in entries)
            AppListTile(
              title: entry.label,
              subtitle: entry.initial.isEmpty
                  ? Copy.recordFieldEmpty
                  : entry.initial,
              dense: true,
            ),
        const SizedBox(height: Space.x4),
        if (detail.audioClips > 0)
          Text(
            Copy.captureAudioCount(detail.audioClips),
            style: AppText.caption,
          ),
        Text(
          Copy.recordCapturedAt(
            DateFormat.yMMMd(
              locale,
            ).add_jm().format(detail.capturedAt.toLocal()),
          ),
          style: AppText.caption,
        ),
      ],
    );
  }
}
