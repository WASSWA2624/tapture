import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/validation/validation_issue.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/quality/quality.dart' show RecordRules;
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, TemplateDef;

import '../domain/record_entry.dart';
import '../domain/record_flag.dart';
import '../domain/record_history_event.dart';
import '../domain/record_value.dart';
import 'record_delete_action.dart';
import 'record_delete_controller.dart';
import 'record_detail_controller.dart';
import 'record_edit_controller.dart' show recordEditTemplateProvider;
import 'record_field_input.dart';
import 'record_field_sheet.dart';
import 'record_history_providers.dart' show recordHistoryProvider;
import 'record_photo_viewer_screen.dart';
import 'record_photos_editor.dart';
import 'record_providers.dart';
import 'record_template_change.dart';

/// One record, read-only, with the entry point to every change (task 014
/// step 4): its status and quality flags, photos (cached thumbnails; the
/// full photo opens only in the viewer, FE-PERF-04), caption and audio,
/// every value with its source and confidence band beside it with no tap
/// to reveal them, the context in force at capture, where the values came
/// from, and when it was captured, changed, approved and exported.
///
/// A tap on a value edits it (FE-CONS-10); Edit values on the Fields
/// heading edits them all; the footer edits photos and captions; the menu
/// changes the template, archives and deletes; History tells the story.
/// Approve and Send to review sit beside the status whenever the lifecycle
/// allows them. A record in the recycle bin is shown read-only with Restore
/// instead.
///
/// [projectId] keeps navigation inside the project the page was opened
/// from; without it, the Records destination's routes are used.
class RecordDetailScreen extends ConsumerWidget {
  /// Creates the page of record [recordId], opened from [projectId] when
  /// one is given.
  const RecordDetailScreen({required this.recordId, this.projectId, super.key});

  /// The record shown.
  final String recordId;

  /// The project the page was opened in, or null from the Records
  /// destination.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<RecordEntry?> record = ref.watch(
      recordEntryProvider(recordId),
    );
    final RecordEntry? entry = record.hasError ? null : record.value;
    if (entry != null && RecordDetailController.canUnarchive(entry.status)) {
      // Kept open while the record is archived, so Unarchive knows the
      // status to return it to.
      ref.watch(recordHistoryProvider(recordId));
    }
    return AppPage(
      key: const ValueKey<String>('route-record'),
      title: entry == null ? Copy.recordDetailTitle : _titleOf(entry),
      subtitle: entry == null ? null : _subtitleOf(entry),
      actions: entry == null
          ? const <Widget>[]
          : <Widget>[
              AppIconButton(
                key: const ValueKey<String>('record-history'),
                icon: AppIcons.history,
                semanticLabel: Copy.recordHistoryTitle,
                tooltip: Copy.recordHistoryTitle,
                onPressed: () => unawaited(context.push<void>(_historyRoute)),
              ),
            ],
      overflow: entry == null
          ? const <AppOverflowAction>[]
          : _menuFor(context, ref, entry),
      footer: entry == null ? null : _footerFor(context, ref, entry),
      body: AsyncValueView<RecordEntry?>(
        value: record,
        loadingShape: SkeletonShape.detail,
        loadingCount: 1,
        isEmpty: (RecordEntry? loaded) => loaded == null,
        empty: () => AppEmptyState(
          icon: AppIcons.records,
          headline: Copy.recordGoneHeadline,
          message: Copy.recordGoneMessage,
          actionLabel: Copy.recordDetailBackToList,
          onAction: () => _backToList(context),
        ),
        onRetry: () => ref.invalidate(recordEntryProvider(recordId)),
        data: (RecordEntry? loaded) =>
            _RecordBody(entry: loaded!, valuesRoute: _valuesRoute),
      ),
    );
  }

  String get _valuesRoute {
    final String? project = projectId;
    return project == null
        ? RoutePaths.recordValuesEdit(recordId)
        : RoutePaths.projectRecordValuesEdit(project, recordId);
  }

  String get _historyRoute {
    final String? project = projectId;
    return project == null
        ? RoutePaths.recordHistory(recordId)
        : RoutePaths.projectRecordHistory(project, recordId);
  }

  String get _listRoute {
    final String? project = projectId;
    return project == null
        ? RoutePaths.records
        : RoutePaths.projectRecords(project);
  }

  /// The labelled commands of the menu. A record in the recycle bin has
  /// none: it is restored first.
  List<AppOverflowAction> _menuFor(
    BuildContext context,
    WidgetRef ref,
    RecordEntry entry,
  ) {
    if (entry.isDeleted) {
      return const <AppOverflowAction>[];
    }
    final RecordStatus status = entry.status;
    return <AppOverflowAction>[
      AppOverflowAction(
        key: const ValueKey<String>('record-menu-values'),
        label: Copy.recordValuesEditTitle,
        icon: AppIcons.edit,
        onTap: () => unawaited(context.push<void>(_valuesRoute)),
      ),
      AppOverflowAction(
        key: const ValueKey<String>('record-menu-template'),
        label: Copy.recordTemplateChangeTitle,
        icon: AppIcons.template,
        onTap: () => unawaited(
          RecordTemplateChange.show(
            context,
            projectId: entry.projectId,
            recordId: entry.id,
          ),
        ),
      ),
      if (RecordDetailController.canArchive(status))
        AppOverflowAction(
          key: const ValueKey<String>('record-menu-archive'),
          label: Copy.recordsArchiveLabel(1),
          icon: AppIcons.archive,
          onTap: () => unawaited(_archive(context, ref, status)),
        ),
      if (RecordDetailController.canUnarchive(status))
        AppOverflowAction(
          key: const ValueKey<String>('record-menu-unarchive'),
          label: Copy.recordDetailUnarchive,
          icon: AppIcons.unarchive,
          onTap: () => unawaited(_unarchive(context, ref)),
        ),
      if (RecordDetailController.canDelete(status))
        AppOverflowAction(
          key: const ValueKey<String>('record-menu-delete'),
          label: Copy.recordsDeleteLabel(1),
          icon: AppIcons.delete,
          onTap: () => unawaited(_delete(context, ref)),
        ),
    ];
  }

  /// Edit photos and captions (FBK0000148), or Restore for a record in the
  /// recycle bin.
  Widget _footerFor(BuildContext context, WidgetRef ref, RecordEntry entry) {
    if (entry.isDeleted) {
      return AppPrimaryAction(
        key: const ValueKey<String>('record-restore'),
        label: Copy.recycleBinRestore,
        busy: ref.watch(recordDeleteControllerProvider),
        onPressed: () => unawaited(_restore(context, ref)),
      );
    }
    return AppPrimaryAction(
      key: const ValueKey<String>('record-edit'),
      label: Copy.recordDetailEditPhotos,
      onPressed: () => unawaited(
        RecordPhotosEditor.open(
          context,
          ref,
          projectId: entry.projectId,
          recordId: entry.id,
        ),
      ),
    );
  }

  /// Archives the record after a confirm, then offers to undo it.
  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    RecordStatus from,
  ) async {
    final RecordDetailController controller = ref.read(
      recordDetailControllerProvider(recordId).notifier,
    );
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.recordsArchiveTitle(1),
      message: Copy.recordsArchiveMessage(1),
      confirmLabel: Copy.recordsArchiveConfirm,
    );
    if (!confirmed) {
      return;
    }
    final Result<void> archived = await controller.archive(from);
    if (archived is! Success<void> || !context.mounted) {
      return;
    }
    showAppSnack(
      context,
      Copy.recordsArchived(1),
      undoLabel: Copy.undo,
      onUndo: () => unawaited(controller.unarchive(previous: from)),
    );
  }

  /// Brings the record back from the archive, to the status its history
  /// says it had before.
  Future<void> _unarchive(BuildContext context, WidgetRef ref) async {
    final List<RecordHistoryEvent>? history = ref
        .read(recordHistoryProvider(recordId))
        .value;
    final Result<void> back = await ref
        .read(recordDetailControllerProvider(recordId).notifier)
        .unarchive(
          previous: history == null
              ? null
              : RecordDetailController.statusBefore(
                  history,
                  RecordStatus.archived,
                ),
        );
    if (back is Success<void> && context.mounted) {
      showAppSnack(context, Copy.recordDetailUnarchived, tone: SnackTone.info);
    }
  }

  /// Moves the record to the recycle bin (confirm, then a snack with undo)
  /// and leaves its page once it is there.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final RecordDeleteOutcome? outcome = await RecordDeleteAction.run(
      context,
      ref,
      ids: <String>[recordId],
    );
    if (outcome == null ||
        !outcome.succeeded.contains(recordId) ||
        !context.mounted) {
      return;
    }
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Brings the record back from the recycle bin, whole.
  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final RecordDeleteOutcome outcome = await ref
        .read(recordDeleteControllerProvider.notifier)
        .restore(<String>[recordId]);
    if (!context.mounted) {
      return;
    }
    final Failure? failure = outcome.failed[recordId];
    if (failure == null) {
      showAppSnack(context, Copy.recordsRestored(1), tone: SnackTone.success);
      return;
    }
    showAppSnack(context, failure.message, tone: SnackTone.error);
  }

  /// Back where the record was opened from, or to its list when the page
  /// was opened on its own.
  void _backToList(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go(_listRoute);
  }
}

/// The record's name, or its number when nothing names it yet.
String _titleOf(RecordEntry entry) {
  return entry.name.trim().isEmpty
      ? Copy.recordsUntitled(entry.number)
      : entry.name;
}

/// Number, identifier and context, as the records list shows them.
String? _subtitleOf(RecordEntry entry) {
  final String line = Copy.recordsRowSubtitle(
    number: entry.number,
    identifier: entry.identifier,
    context: entry.contextLabel,
  );
  return line.isEmpty ? null : line;
}

/// Everything the page shows of a loaded record, top to bottom.
class _RecordBody extends ConsumerWidget {
  const _RecordBody({required this.entry, required this.valuesRoute});

  final RecordEntry entry;

  /// Where Edit values on the Fields heading goes.
  final String valuesRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TemplateDef?> template = ref.watch(
      recordEditTemplateProvider(entry.templateId),
    );
    final RecordDetailState state = ref.watch(
      recordDetailControllerProvider(entry.id),
    );
    final Failure? failure = state.failure;
    final _Labels labels = _Labels(template.hasError ? null : template.value);
    final bool summarised = entry.values.any(
      (RecordValue value) => value.hasValue,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (entry.isDeleted) ...<Widget>[
          const AppBanner(
            key: ValueKey<String>('record-deleted-notice'),
            message: Copy.recordDetailDeletedNotice,
            icon: AppIcons.delete,
            tone: SnackTone.warning,
          ),
          const SizedBox(height: Space.x3),
        ],
        if (failure != null) ...<Widget>[
          AppBanner(
            key: const ValueKey<String>('record-detail-failure'),
            message: <String>[
              failure.message,
              ?failure.recoveryAction,
            ].join(' '),
            icon: AppIcons.error,
            tone: SnackTone.error,
            onDismiss: () => ref
                .read(recordDetailControllerProvider(entry.id).notifier)
                .dismissFailure(),
          ),
          const SizedBox(height: Space.x3),
        ],
        _Header(entry: entry, busy: state.busy),
        if (entry.photos.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x4),
          _Photos(entry: entry),
        ],
        const SizedBox(height: Space.x4),
        _Caption(entry: entry),
        const SizedBox(height: Space.x4),
        _Fields(entry: entry, template: template, valuesRoute: valuesRoute),
        const SizedBox(height: Space.x4),
        _Context(entry: entry, labels: labels),
        if (summarised) ...<Widget>[
          const SizedBox(height: Space.x4),
          _Provenance(entry: entry),
        ],
        const SizedBox(height: Space.x4),
        _Dates(entry: entry),
      ],
    );
  }
}

/// The status, the next step the lifecycle allows (Approve, or Send to
/// review), and the quality flags.
class _Header extends ConsumerWidget {
  const _Header({required this.entry, required this.busy});

  final RecordEntry entry;

  /// Whether a status move is being written.
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecordStatus status = entry.status;
    final List<RecordFlag> flags = <RecordFlag>[
      for (final RecordFlag flag in RecordFlag.values)
        if (flag != RecordFlag.hasPhotos && entry.flags.contains(flag)) flag,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: Space.x2,
          runSpacing: Space.x2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            AppStatusPill(
              key: const ValueKey<String>('record-status'),
              status: status,
            ),
            if (RecordDetailController.canApprove(status))
              AppButton(
                key: const ValueKey<String>('record-approve'),
                label: Copy.recordsApproveLabel(1),
                icon: AppIcons.verified,
                variant: AppButtonVariant.secondary,
                busy: busy,
                onPressed: () => unawaited(_approve(context, ref)),
              ),
            if (RecordDetailController.canSendToReview(status))
              AppButton(
                key: const ValueKey<String>('record-send-to-review'),
                label: Copy.recordDetailSendToReview,
                icon: AppIcons.review,
                variant: AppButtonVariant.secondary,
                busy: busy,
                onPressed: () => unawaited(_sendToReview(context, ref)),
              ),
          ],
        ),
        if (flags.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x2),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x1,
            children: <Widget>[
              for (final RecordFlag flag in flags)
                AppChip(
                  key: ValueKey<String>('record-flag-${flag.name}'),
                  label: _flagLabel(flag),
                  icon: _flagIcon(flag),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final TemplateDef? template = ref
        .read(recordEditTemplateProvider(entry.templateId))
        .asData
        ?.value;
    if (template != null) {
      final List<ValidationIssue> issues = RecordRules.validateRecord(
        template: template,
        values: <String, Object?>{
          for (final RecordValue value in entry.values)
            value.fieldKey: value.display,
        },
        hasEvidence: entry.photos.isNotEmpty,
        conflicts: <String>[
          for (final RecordValue value in entry.values)
            if (value.evidenceRemoved) value.fieldKey,
        ],
      );
      final ValidationIssue? block = issues
          .where((ValidationIssue issue) => issue.blocks)
          .firstOrNull;
      if (block != null && context.mounted) {
        showAppSnack(context, block.message, tone: SnackTone.error);
        return;
      }
    }
    final Result<void> approved = await ref
        .read(recordDetailControllerProvider(entry.id).notifier)
        .approve(entry.status);
    if (approved is Success<void> && context.mounted) {
      showAppSnack(context, Copy.recordsApproved(1), tone: SnackTone.success);
    }
  }

  Future<void> _sendToReview(BuildContext context, WidgetRef ref) async {
    final Result<void> sent = await ref
        .read(recordDetailControllerProvider(entry.id).notifier)
        .sendToReview(entry.status);
    if (sent is Success<void> && context.mounted) {
      showAppSnack(
        context,
        Copy.recordDetailSentToReview,
        tone: SnackTone.success,
      );
    }
  }
}

/// The record's photos as cached thumbnails; a tap opens the full photo in
/// the viewer, the only place the original is decoded (FE-PERF-04).
class _Photos extends StatelessWidget {
  const _Photos({required this.entry});

  final RecordEntry entry;

  @override
  Widget build(BuildContext context) {
    final int total = entry.photos.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: Copy.capturePhotosSection),
        Wrap(
          spacing: Space.x2,
          runSpacing: Space.x2,
          children: <Widget>[
            for (int index = 0; index < total; index++)
              RecordThumb(
                key: ValueKey<String>('record-photo-${entry.photos[index].id}'),
                sha256: entry.photos[index].sha256,
                storagePath: entry.photos[index].storagePath,
                quarterTurns: entry.photos[index].quarterTurns,
                size: Space.x12 * 2,
                hasCaption: entry.photos[index].hasCaption,
                semanticLabel: Copy.recordPhotoPosition(index + 1, total),
                onTap: () => unawaited(
                  RecordPhotoViewerScreen.open(
                    context,
                    photos: entry.photos,
                    initialIndex: index,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The record's own caption and how many audio clips it holds.
class _Caption extends StatelessWidget {
  const _Caption({required this.entry});

  final RecordEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String caption = entry.caption.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: Copy.captureRecordCaption),
        Text(
          caption.isEmpty ? Copy.recordNoCaption : entry.caption,
          key: const ValueKey<String>('record-caption'),
          style: AppText.body.copyWith(color: colors.onSurface),
        ),
        if (entry.audioClips > 0) ...<Widget>[
          const SizedBox(height: Space.x1),
          Text(
            Copy.captureAudioCount(entry.audioClips),
            key: const ValueKey<String>('record-audio'),
            style: AppText.caption.copyWith(color: colors.onSurface),
          ),
        ],
      ],
    );
  }
}

/// One value row: which field, what it holds and where it came from, and
/// whether it is kept as retired.
typedef _Row = ({
  String fieldKey,
  String label,
  RecordValue? value,
  bool retired,
  bool tappable,
});

/// Every value in the template's field order, each with its source and
/// band, then the values kept as retired. A tap opens the one-value sheet:
/// editable for a live field, read-only for a retired value.
class _Fields extends ConsumerWidget {
  const _Fields({
    required this.entry,
    required this.template,
    required this.valuesRoute,
  });

  final RecordEntry entry;
  final AsyncValue<TemplateDef?> template;
  final String valuesRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (template) {
      AsyncData<TemplateDef?>(:final TemplateDef? value) => _loaded(
        context,
        value,
      ),
      AsyncError<TemplateDef?>(:final Object error) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const AppSectionHeader(title: Copy.recordSectionFields),
          AppErrorState(
            failure: Failure.from(error),
            onRetry: () =>
                ref.invalidate(recordEditTemplateProvider(entry.templateId)),
          ),
          // The labels could not be read; the values still show, by key.
          ..._tiles(context, _unlabelled()),
        ],
      ),
      _ => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSectionHeader(title: Copy.recordSectionFields),
          AppSkeleton(count: 2),
        ],
      ),
    };
  }

  Widget _loaded(BuildContext context, TemplateDef? template) {
    final bool deleted = entry.isDeleted;
    final List<RecordEditEntry> editable = template == null || deleted
        ? const <RecordEditEntry>[]
        : recordEditEntries(template: template, record: entry);
    final Set<String> editableKeys = <String>{
      for (final RecordEditEntry field in editable) field.fieldKey,
    };
    final _Labels labels = _Labels(template);
    final List<_Row> live = template == null
        ? const <_Row>[]
        : <_Row>[
            for (final FieldDef field in _shownFields(template))
              if (!(entry.valueOf(field.fieldKey)?.retired ?? false))
                (
                  fieldKey: field.fieldKey,
                  label: labels.of(field.fieldKey),
                  value: entry.valueOf(field.fieldKey),
                  retired: false,
                  tappable: editableKeys.contains(field.fieldKey),
                ),
          ];
    final List<_Row> retired = <_Row>[
      for (final RecordValue value in recordRetiredValues(
        template: template,
        record: entry,
      ))
        (
          fieldKey: value.fieldKey,
          label: labels.of(value.fieldKey),
          value: value,
          retired: true,
          tappable: !deleted,
        ),
    ];
    final AppColors colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: Copy.recordSectionFields,
          // An icon beside the heading fits at 200 percent text on a
          // phone, where a worded button would push the heading off.
          action: editable.isEmpty
              ? null
              : AppIconButton(
                  key: const ValueKey<String>('record-edit-fields'),
                  icon: AppIcons.edit,
                  tooltip: Copy.recordValuesEditTitle,
                  semanticLabel: Copy.recordValuesEditTitle,
                  onPressed: () => unawaited(context.push<void>(valuesRoute)),
                ),
        ),
        if (template == null) ...<Widget>[
          const AppBanner(
            key: ValueKey<String>('record-template-missing'),
            message: Copy.recordTemplateMissingNotice,
            icon: AppIcons.template,
            tone: SnackTone.info,
          ),
          const SizedBox(height: Space.x2),
        ],
        if (live.isEmpty && retired.isEmpty)
          Text(
            Copy.recordDetailNoValues,
            key: const ValueKey<String>('record-no-values'),
            style: AppText.body.copyWith(color: colors.onSurface),
          ),
        ..._tiles(context, live),
        if (retired.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x3),
          const AppSectionHeader(
            title: Copy.recordRetiredValuesTitle,
            dense: true,
          ),
          Text(
            Copy.recordRetiredValuesMessage,
            style: AppText.caption.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: Space.x1),
          ..._tiles(context, retired),
        ],
      ],
    );
  }

  /// Every value by its key, for when the template cannot be read. Each
  /// still opens its sheet, which says what it can.
  List<_Row> _unlabelled() {
    return <_Row>[
      for (final RecordValue value in entry.values)
        (
          fieldKey: value.fieldKey,
          label: value.fieldKey,
          value: value,
          retired: value.retired,
          tappable: !entry.isDeleted,
        ),
    ];
  }

  List<Widget> _tiles(BuildContext context, List<_Row> rows) {
    return <Widget>[
      for (final _Row row in rows)
        _ValueTile(
          row: row,
          onTap: row.tappable
              ? () => unawaited(
                  RecordFieldSheet.show(
                    context,
                    recordId: entry.id,
                    fieldKey: row.fieldKey,
                    label: row.label,
                  ),
                )
              : null,
        ),
    ];
  }
}

/// The template's fields a person sees, in its order: every field that is
/// not hidden, typed, picked, filled in or computed alike.
List<FieldDef> _shownFields(TemplateDef template) {
  final List<FieldDef> fields = <FieldDef>[
    for (final FieldDef field in template.fields)
      if (!field.hidden) field,
  ];
  final List<int> order = List<int>.generate(fields.length, (int i) => i)
    ..sort((int a, int b) {
      final int bySort = fields[a].sortOrder.compareTo(fields[b].sortOrder);
      return bySort != 0 ? bySort : a.compareTo(b);
    });
  return <FieldDef>[for (final int index in order) fields[index]];
}

/// One value: its field's label, what it holds, and beside it where it came
/// from and how sure the reading was, with no tap needed to see them.
class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.row, required this.onTap});

  final _Row row;

  /// Opens the value's sheet; null when the value cannot be opened here.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final RecordValue? value = row.value;
    final bool filled = value != null && value.hasValue;
    return AppListTile(
      key: ValueKey<String>('record-field-${row.fieldKey}'),
      title: row.label,
      subtitle: filled ? value.display : Copy.recordFieldEmpty,
      dense: true,
      trailing: filled
          ? _ValueMarks(value: value, retired: row.retired)
          : row.retired
          ? const AppStatusPill.badge(
              status: RecordStatus.archived,
              label: Copy.recordValueRetired,
            )
          : null,
      onTap: onTap,
    );
  }
}

/// Where [value] came from, how sure the reading was, and whether it lost
/// its photo evidence or was retired, stacked beside the value. Read as one
/// phrase by a screen reader.
class _ValueMarks extends StatelessWidget {
  const _ValueMarks({required this.value, required this.retired});

  final RecordValue value;
  final bool retired;

  @override
  Widget build(BuildContext context) {
    final ValueSource source = value.valueSource;
    final String sourceLabel = _sourceLabel(source);
    final _Band? band = _bandOf(value);
    return Semantics(
      label: Copy.recordValueMarks(
        source: sourceLabel,
        band: band?.label ?? '',
        evidenceRemoved: value.evidenceRemoved,
        retired: retired,
      ),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          // The value keeps most of the row; a long mark shortens instead.
          constraints: BoxConstraints(
            maxWidth: context.responsive<double>(
              compact: Space.x12 * 3,
              medium: Space.x12 * 4,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              AppChip(
                key: ValueKey<String>('record-source-${value.fieldKey}'),
                label: sourceLabel,
                icon: _sourceIcon(source),
              ),
              if (band != null) ...<Widget>[
                const SizedBox(height: Space.x1),
                AppStatusPill.badge(
                  key: ValueKey<String>('record-band-${value.fieldKey}'),
                  status: band.tone,
                  label: band.label,
                ),
              ],
              if (value.evidenceRemoved) ...<Widget>[
                const SizedBox(height: Space.x1),
                AppStatusPill.badge(
                  key: ValueKey<String>(
                    'record-evidence-removed-${value.fieldKey}',
                  ),
                  status: RecordStatus.needsReview,
                  label: Copy.recordValueEvidenceRemoved,
                ),
              ],
              if (retired) ...<Widget>[
                const SizedBox(height: Space.x1),
                AppStatusPill.badge(
                  key: ValueKey<String>('record-retired-${value.fieldKey}'),
                  status: RecordStatus.archived,
                  label: Copy.recordValueRetired,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// How sure a reading was: the pill's colour and icon, and its words.
typedef _Band = ({RecordStatus tone, String label});

/// The band [value] was read with: its stored band, else its score as a
/// percentage. A value typed by a person has none, whatever an earlier
/// reading scored.
_Band? _bandOf(RecordValue value) {
  if (value.valueSource == ValueSource.manual) {
    return null;
  }
  final String stored = (value.band ?? '').toLowerCase().replaceAll(
    _nonLetter,
    '',
  );
  switch (stored) {
    case 'high':
      return (tone: RecordStatus.approved, label: Copy.recordBandHigh);
    case 'medium':
      return (tone: RecordStatus.needsReview, label: Copy.recordBandMedium);
    case 'reviewrequired' || 'low':
      return (tone: RecordStatus.failed, label: Copy.recordBandLow);
  }
  final double? score = value.confidence;
  if (score == null) {
    return null;
  }
  return (tone: RecordStatus.extracted, label: Copy.recordBandScore(score));
}

final RegExp _nonLetter = RegExp('[^a-z]');

/// Where a value came from, in the operator's words.
String _sourceLabel(ValueSource source) {
  return switch (source) {
    ValueSource.manual => Copy.recordSourceTyped,
    ValueSource.ocr => Copy.recordSourceOcr,
    ValueSource.aiVision => Copy.recordSourceAiPhoto,
    ValueSource.aiText => Copy.recordSourceAiText,
    ValueSource.stt => Copy.recordSourceSpeech,
    ValueSource.barcode => Copy.recordSourceBarcode,
    ValueSource.lookup => Copy.recordSourceLookup,
    ValueSource.context => Copy.recordSourceContext,
    ValueSource.auto => Copy.recordSourceDefault,
    ValueSource.import => Copy.recordSourceImported,
  };
}

/// The glyph of a value's source (FE-CONS-08).
IconData _sourceIcon(ValueSource source) {
  return switch (source) {
    ValueSource.manual => AppIcons.edit,
    ValueSource.ocr => AppIcons.typeText,
    ValueSource.aiVision => AppIcons.ai,
    ValueSource.aiText => AppIcons.caption,
    ValueSource.stt => AppIcons.dictate,
    ValueSource.barcode => AppIcons.detection,
    ValueSource.lookup => AppIcons.dataset,
    ValueSource.context => AppIcons.context,
    ValueSource.auto => AppIcons.template,
    ValueSource.import => AppIcons.import,
  };
}

/// A quality flag in the records list's words.
String _flagLabel(RecordFlag flag) {
  return switch (flag) {
    RecordFlag.hasPhotos => Copy.recordsFlagHasPhotos,
    RecordFlag.hasDuplicate => Copy.recordsFlagHasDuplicate,
    RecordFlag.hasConflict => Copy.recordsFlagHasConflict,
    RecordFlag.hasVariance => Copy.recordsFlagHasVariance,
    RecordFlag.evidenceRemoved => Copy.recordsFlagEvidenceRemoved,
    RecordFlag.mergedFromBundle => Copy.recordsFlagMerged,
  };
}

IconData _flagIcon(RecordFlag flag) {
  return switch (flag) {
    RecordFlag.hasPhotos => AppIcons.photoLibrary,
    RecordFlag.hasDuplicate => AppIcons.duplicate,
    RecordFlag.hasConflict => AppIcons.warning,
    RecordFlag.hasVariance => AppIcons.review,
    RecordFlag.evidenceRemoved => AppIcons.brokenFile,
    RecordFlag.mergedFromBundle => AppIcons.merge,
  };
}

/// Field labels from the record's template, which is data; a key no
/// template declares shows as itself.
final class _Labels {
  _Labels(TemplateDef? template)
    : _byKey = <String, String>{
        for (final FieldDef field in template?.fields ?? const <FieldDef>[])
          if (field.label.trim().isNotEmpty) field.fieldKey: field.label,
      };

  final Map<String, String> _byKey;

  String of(String fieldKey) => _byKey[fieldKey] ?? fieldKey;
}

/// The context in force when the record was captured, level by level.
class _Context extends StatelessWidget {
  const _Context({required this.entry, required this.labels});

  final RecordEntry entry;
  final _Labels labels;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> levels = <MapEntry<String, String>>[
      for (final MapEntry<String, String> level in entry.context.entries)
        if (level.value.trim().isNotEmpty) level,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: Copy.recordDetailContextTitle),
        if (levels.isEmpty)
          Text(
            Copy.recordDetailContextEmpty,
            key: const ValueKey<String>('record-context-empty'),
            style: AppText.body.copyWith(color: context.colors.onSurface),
          )
        else
          for (final MapEntry<String, String> level in levels)
            AppListTile(
              key: ValueKey<String>('record-context-${level.key}'),
              title: labels.of(level.key),
              subtitle: level.value,
              dense: true,
            ),
      ],
    );
  }
}

/// Where the record's values came from: how many from each source, how
/// many a person confirmed or lost their photo evidence, and which
/// providers, models or methods read them.
class _Provenance extends StatelessWidget {
  const _Provenance({required this.entry});

  final RecordEntry entry;

  @override
  Widget build(BuildContext context) {
    final List<RecordValue> filled = <RecordValue>[
      for (final RecordValue value in entry.values)
        if (value.hasValue) value,
    ];
    final Map<ValueSource, int> bySource = <ValueSource, int>{};
    for (final RecordValue value in filled) {
      bySource.update(value.valueSource, (int n) => n + 1, ifAbsent: () => 1);
    }
    final int verified = filled.where((RecordValue v) => v.verified).length;
    final int removed = filled
        .where((RecordValue v) => v.evidenceRemoved)
        .length;
    final Set<String> readers = <String>{
      for (final RecordValue value in filled) ?_readerOf(value),
    };
    final Color icon = context.colors.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: Copy.recordDetailProvenanceTitle),
        for (final ValueSource source in ValueSource.values)
          if ((bySource[source] ?? 0) > 0)
            AppListTile(
              key: ValueKey<String>('record-provenance-${source.name}'),
              leading: Icon(_sourceIcon(source), color: icon),
              title: _sourceLabel(source),
              subtitle: Copy.recordDetailValuesCount(bySource[source]!),
              dense: true,
            ),
        if (verified > 0)
          AppListTile(
            key: const ValueKey<String>('record-provenance-verified'),
            leading: Icon(AppIcons.verified, color: icon),
            title: Copy.recordDetailVerified,
            subtitle: Copy.recordDetailValuesCount(verified),
            dense: true,
          ),
        if (removed > 0)
          AppListTile(
            key: const ValueKey<String>('record-provenance-evidence'),
            leading: Icon(AppIcons.brokenFile, color: icon),
            title: Copy.recordValueEvidenceRemoved,
            subtitle: Copy.recordDetailValuesCount(removed),
            dense: true,
          ),
        if (readers.isNotEmpty)
          AppListTile(
            key: const ValueKey<String>('record-provenance-readers'),
            leading: Icon(AppIcons.ai, color: icon),
            title: Copy.recordDetailReadBy,
            subtitle: readers.join(', '),
            dense: true,
          ),
      ],
    );
  }
}

/// Who read [value]: its provider and model, else its method; null when
/// neither is known.
String? _readerOf(RecordValue value) {
  final String named = <String>[
    ?value.provider?.trim(),
    ?value.model?.trim(),
  ].where((String part) => part.isNotEmpty).join(' ');
  if (named.isNotEmpty) {
    return named;
  }
  final String method = value.method?.trim() ?? '';
  return method.isEmpty ? null : method;
}

/// When the record was captured and on which device, last changed,
/// approved and by whom, and exported.
class _Dates extends StatelessWidget {
  const _Dates({required this.entry});

  final RecordEntry entry;

  @override
  Widget build(BuildContext context) {
    final DateTime? approvedAt = entry.approvedAt;
    final DateTime? exportedAt = entry.exportedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: Copy.recordDetailDatesTitle),
        AppListTile(
          key: const ValueKey<String>('record-date-captured'),
          title: Copy.recordDetailCaptured,
          subtitle: Copy.recordDetailWhen(
            entry.capturedAt.toLocal(),
            by: entry.capturedBy,
          ),
          dense: true,
        ),
        AppListTile(
          key: const ValueKey<String>('record-date-updated'),
          title: Copy.recordDetailUpdated,
          subtitle: Copy.recordDetailWhen(entry.updatedAt.toLocal()),
          dense: true,
        ),
        if (approvedAt != null)
          AppListTile(
            key: const ValueKey<String>('record-date-approved'),
            title: Copy.recordDetailApproved,
            subtitle: Copy.recordDetailWhen(
              approvedAt.toLocal(),
              by: entry.approvedBy ?? '',
            ),
            dense: true,
          ),
        AppListTile(
          key: const ValueKey<String>('record-date-exported'),
          title: Copy.recordDetailExported,
          subtitle: exportedAt == null
              ? Copy.recordDetailNotExported
              : Copy.recordDetailWhen(exportedAt.toLocal()),
          dense: true,
        ),
      ],
    );
  }
}
