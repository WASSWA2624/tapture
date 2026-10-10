import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/speech/speech_readiness_notifier.dart';
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
import 'package:tapture/core/widgets/responsive/content_constraint.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/processing/processing.dart'
    show ConfidenceBand, ConfidenceIndicator;
import 'package:tapture/features/quality/quality.dart' show DuplicateLinks;
import 'package:tapture/features/review/review.dart' show ReviewApproval;
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, TemplateDef;
import 'package:tapture/features/transcripts/transcripts.dart'
    show
        TranscriptListSection,
        TranscriptStart,
        TranscriptSummary,
        recordAudioTranscriptionControllerProvider,
        recordUntranscribedAudioProvider;

import '../domain/record_entry.dart';
import '../domain/record_flag.dart';
import '../domain/record_history_event.dart';
import '../domain/record_value.dart';
import 'record_delete_action.dart';
import 'record_delete_controller.dart';
import 'record_detail_controller.dart';
import 'record_edit_controller.dart'
    show recordEditTemplateProvider, recordCapturedTemplateProvider;
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
/// from; legacy addresses resolve to the record's owning project.
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
    final LocalizedCopy localCopy = Copy.of(context);

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
      title: entry == null
          ? localCopy.recordDetailTitle
          : _titleOf(entry, localizedCopy: Copy.of(context)),
      subtitle: entry == null
          ? null
          : _subtitleOf(entry, localizedCopy: Copy.of(context)),
      scrollable: entry == null,
      actions: entry == null
          ? const <Widget>[]
          : <Widget>[
              AppIconButton(
                key: const ValueKey<String>('record-history'),
                icon: AppIcons.history,
                semanticLabel: localCopy.recordHistoryTitle,
                tooltip: localCopy.recordHistoryTitle,
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
          headline: Copy.of(context).recordGoneHeadline,
          message: Copy.of(context).recordGoneMessage,
          actionLabel: Copy.of(context).recordDetailBackToList,
          onAction: () => _backToList(context),
        ),
        onRetry: () => ref.invalidate(recordEntryProvider(recordId)),
        data: (RecordEntry? loaded) => _RecordBody(
          entry: loaded!,
          valuesRoute: _valuesRoute,
          openTranscript: (String transcriptId) =>
              _openTranscript(context, transcriptId),
        ),
      ),
    );
  }

  String get _valuesRoute {
    final String? project = projectId;
    return project == null
        ? RoutePaths.recordValuesEdit(recordId)
        : RoutePaths.projectRecordValuesEdit(project, recordId);
  }

  /// Opens transcript [transcriptId]: over this page inside its project,
  /// otherwise in the transcript history.
  void _openTranscript(BuildContext context, String transcriptId) {
    final String? project = projectId;
    if (project == null) {
      context.go(RoutePaths.transcript(transcriptId));
    } else {
      unawaited(
        context.push<void>(RoutePaths.projectTranscript(project, transcriptId)),
      );
    }
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
    final LocalizedCopy localCopy = Copy.of(context);

    if (entry.isDeleted) {
      return const <AppOverflowAction>[];
    }
    final RecordStatus status = entry.status;
    return <AppOverflowAction>[
      AppOverflowAction(
        key: const ValueKey<String>('record-menu-values'),
        label: localCopy.recordValuesEditTitle,
        icon: AppIcons.edit,
        onTap: () => unawaited(context.push<void>(_valuesRoute)),
      ),
      AppOverflowAction(
        key: const ValueKey<String>('record-menu-template'),
        label: localCopy.recordTemplateChangeTitle,
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
          label: localCopy.recordsArchiveLabel(1),
          icon: AppIcons.archive,
          onTap: () => unawaited(_archive(context, ref, status)),
        ),
      if (RecordDetailController.canUnarchive(status))
        AppOverflowAction(
          key: const ValueKey<String>('record-menu-unarchive'),
          label: localCopy.recordDetailUnarchive,
          icon: AppIcons.unarchive,
          onTap: () => unawaited(_unarchive(context, ref)),
        ),
      if (RecordDetailController.canDelete(status))
        AppOverflowAction(
          key: const ValueKey<String>('record-menu-delete'),
          label: localCopy.recordsDeleteLabel(1),
          icon: AppIcons.delete,
          onTap: () => unawaited(_delete(context, ref)),
        ),
    ];
  }

  /// Edit photos and captions (FBK0000148), or Restore for a record in the
  /// recycle bin.
  Widget _footerFor(BuildContext context, WidgetRef ref, RecordEntry entry) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (entry.isDeleted) {
      return AppPrimaryAction(
        key: const ValueKey<String>('record-restore'),
        label: localCopy.recycleBinRestore,
        busy: ref.watch(recordDeleteControllerProvider),
        onPressed: () => unawaited(_restore(context, ref)),
      );
    }
    return AppPrimaryAction(
      key: const ValueKey<String>('record-edit'),
      label: localCopy.recordDetailEditPhotos,
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
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordDetailController controller = ref.read(
      recordDetailControllerProvider(recordId).notifier,
    );
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.recordsArchiveTitle(1),
      message: localCopy.recordsArchiveMessage(1),
      confirmLabel: localCopy.recordsArchiveConfirm,
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
      localCopy.recordsArchived(1),
      undoLabel: localCopy.undo,
      onUndo: () => unawaited(controller.unarchive(previous: from)),
    );
  }

  /// Brings the record back from the archive, to the status its history
  /// says it had before.
  Future<void> _unarchive(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);

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
      showAppSnack(
        context,
        localCopy.recordDetailUnarchived,
        tone: SnackTone.info,
      );
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
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordDeleteOutcome outcome = await ref
        .read(recordDeleteControllerProvider.notifier)
        .restore(<String>[recordId]);
    if (!context.mounted) {
      return;
    }
    final Failure? failure = outcome.failed[recordId];
    if (failure == null) {
      showAppSnack(
        context,
        localCopy.recordsRestored(1),
        tone: SnackTone.success,
      );
      return;
    }
    showAppSnack(
      context,
      failure.message,
      tone: SnackTone.error,
      localizedMessage: failure.explanation,
    );
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
String _titleOf(RecordEntry entry, {LocalizedCopy? localizedCopy}) {
  return entry.name.trim().isEmpty
      ? (localizedCopy ?? Copy.english).recordsUntitled(entry.number)
      : entry.name;
}

/// Number, identifier and context, as the records list shows them.
String? _subtitleOf(RecordEntry entry, {LocalizedCopy? localizedCopy}) {
  final String line = (localizedCopy ?? Copy.english).recordsRowSubtitle(
    number: entry.number,
    identifier: entry.identifier,
    context: entry.contextLabel,
  );
  return line.isEmpty ? null : line;
}

/// Everything the page shows of a loaded record, top to bottom.
class _RecordBody extends ConsumerWidget {
  const _RecordBody({
    required this.entry,
    required this.valuesRoute,
    required this.openTranscript,
  });

  final RecordEntry entry;

  /// Where Edit values on the Fields heading goes.
  final String valuesRoute;

  /// Opens a transcript of the record's audio.
  final ValueChanged<String> openTranscript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<TemplateDef?> template = ref.watch(
      recordCapturedTemplateProvider((
        id: entry.templateId,
        version: entry.templateVersion,
      )),
    );
    final RecordDetailState state = ref.watch(
      recordDetailControllerProvider(entry.id),
    );
    final Failure? failure = state.failure;
    final _Labels labels = _Labels(template.hasError ? null : template.value);
    final bool summarised = entry.values.any(
      (RecordValue value) => value.hasValue,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPage.gutter(context)),
      child: ContentConstraint(
        child: CustomScrollView(
          key: const ValueKey<String>('record-detail-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: <Widget>[
            const SliverToBoxAdapter(child: SizedBox(height: Space.x2)),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (entry.isDeleted) ...<Widget>[
                    AppBanner(
                      key: const ValueKey<String>('record-deleted-notice'),
                      message: localCopy.recordDetailDeletedNotice,
                      icon: AppIcons.delete,
                      tone: SnackTone.warning,
                    ),
                    const SizedBox(height: Space.x3),
                  ],
                  if (failure != null) ...<Widget>[
                    AppBanner(
                      key: const ValueKey<String>('record-detail-failure'),
                      message: <String>[
                        Copy.of(context).failureMessage(failure),
                        ?Copy.of(context).failureRecovery(failure),
                      ].join(' '),
                      icon: AppIcons.error,
                      tone: SnackTone.error,
                      onDismiss: () => ref
                          .read(
                            recordDetailControllerProvider(entry.id).notifier,
                          )
                          .dismissFailure(),
                    ),
                    const SizedBox(height: Space.x3),
                  ],
                  _Header(entry: entry, busy: state.busy),
                ],
              ),
            ),
            if (entry.photos.isNotEmpty) ...<Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: Space.x4),
                  child: AppSectionHeader(
                    title: localCopy.capturePhotosSection,
                  ),
                ),
              ),
              _Photos(entry: entry),
            ],
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: Space.x4),
                  _Caption(entry: entry),
                  _Transcripts(entry: entry, open: openTranscript),
                  const SizedBox(height: Space.x4),
                  _Fields(
                    entry: entry,
                    template: template,
                    valuesRoute: valuesRoute,
                  ),
                  const SizedBox(height: Space.x4),
                  _Context(entry: entry, labels: labels),
                  if (summarised) ...<Widget>[
                    const SizedBox(height: Space.x4),
                    _Provenance(entry: entry),
                  ],
                  const SizedBox(height: Space.x4),
                  _Dates(entry: entry),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: Space.x2)),
          ],
        ),
      ),
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
    final LocalizedCopy localCopy = Copy.of(context);

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
                label: localCopy.recordsApproveLabel(1),
                icon: AppIcons.verified,
                variant: AppButtonVariant.secondary,
                busy: busy,
                onPressed: () => unawaited(_approve(context, ref)),
              ),
            if (status == RecordStatus.needsReview)
              AppButton(
                key: const ValueKey<String>('record-review'),
                label: localCopy.reviewTitle,
                icon: AppIcons.review,
                variant: AppButtonVariant.secondary,
                onPressed: () => unawaited(
                  context.push<void>(
                    RoutePaths.projectRecordReview(entry.projectId, entry.id),
                  ),
                ),
              ),
            if (RecordDetailController.canSendToReview(status))
              AppButton(
                key: const ValueKey<String>('record-send-to-review'),
                label: localCopy.recordDetailSendToReview,
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
                  label: _flagLabel(flag, localizedCopy: Copy.of(context)),
                  icon: _flagIcon(flag),
                ),
            ],
          ),
        ],
        DuplicateLinks(projectId: entry.projectId, recordId: entry.id),
      ],
    );
  }

  /// Approves through review's one approval path, so validation, an
  /// unresolved duplicate and an unresolved conflict block here as they do
  /// everywhere, naming the field (task 016).
  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    await ReviewApproval.approve(context, ref, recordId: entry.id);
  }

  Future<void> _sendToReview(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Result<void> sent = await ref
        .read(recordDetailControllerProvider(entry.id).notifier)
        .sendToReview(entry.status);
    if (sent is Success<void> && context.mounted) {
      showAppSnack(
        context,
        localCopy.recordDetailSentToReview,
        tone: SnackTone.success,
      );
    }
  }
}

/// A lazy sliver of cached thumbnails; only visible rows and the viewport's
/// cache mount thumbnail providers (FE-PERF-03, FE-PERF-04).
class _Photos extends StatelessWidget {
  const _Photos({required this.entry});

  final RecordEntry entry;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final int total = entry.photos.length;
    const double edge = Space.x12 * 2;
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final int columns =
            ((constraints.crossAxisExtent + Space.x2) / (edge + Space.x2))
                .floor()
                .clamp(1, total)
                .toInt();
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: edge,
            crossAxisSpacing: Space.x2,
            mainAxisSpacing: Space.x2,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => Align(
              alignment: AlignmentDirectional.topStart,
              child: RecordThumb(
                key: ValueKey<String>('record-photo-${entry.photos[index].id}'),
                sha256: entry.photos[index].sha256,
                storagePath: entry.photos[index].storagePath,
                quarterTurns: entry.photos[index].quarterTurns,
                size: edge,
                hasCaption: entry.photos[index].hasCaption,
                semanticLabel: localCopy.recordPhotoPosition(index + 1, total),
                onTap: () => unawaited(
                  RecordPhotoViewerScreen.open(
                    context,
                    photos: entry.photos,
                    initialIndex: index,
                  ),
                ),
              ),
            ),
            childCount: total,
            addAutomaticKeepAlives: false,
          ),
        );
      },
    );
  }
}

/// The record's own caption and how many audio clips it holds.
class _Caption extends StatelessWidget {
  const _Caption({required this.entry});

  final RecordEntry entry;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppColors colors = context.colors;
    final String caption = entry.caption.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: localCopy.captureRecordCaption),
        Text(
          caption.isEmpty ? localCopy.recordNoCaption : entry.caption,
          key: const ValueKey<String>('record-caption'),
          style: AppText.body.copyWith(color: colors.onSurface),
        ),
        if (entry.audioClips > 0) ...<Widget>[
          const SizedBox(height: Space.x1),
          Text(
            localCopy.captureAudioCount(entry.audioClips),
            key: const ValueKey<String>('record-audio'),
            style: AppText.caption.copyWith(color: colors.onSurface),
          ),
        ],
      ],
    );
  }
}

/// The transcripts heard from the record's audio, and **Transcribe on this
/// device** while a speech model is ready and a clip has none (task 125).
/// Shows nothing for a record without either.
class _Transcripts extends ConsumerWidget {
  const _Transcripts({required this.entry, required this.open});

  final RecordEntry entry;

  /// Opens a transcript by id.
  final ValueChanged<String> open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);
    final bool canTranscribe =
        entry.audioClips > 0 &&
        !entry.isDeleted &&
        ref.watch(speechReadinessProvider).ready;
    final List<TranscriptStart> untranscribed = canTranscribe
        ? ref.watch(recordUntranscribedAudioProvider(entry.id)).value ??
              const <TranscriptStart>[]
        : const <TranscriptStart>[];
    final bool running = ref.watch(
      recordAudioTranscriptionControllerProvider(entry.id),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TranscriptListSection(
          recordId: entry.id,
          onOpen: (TranscriptSummary transcript) => open(transcript.id),
        ),
        if (running || untranscribed.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              key: const ValueKey<String>('record-transcribe-on-device'),
              label: localCopy.transcriptTranscribeOnDevice,
              icon: AppIcons.transcript,
              variant: AppButtonVariant.secondary,
              busy: running,
              onPressed: running
                  ? null
                  : () => unawaited(_transcribe(context, ref)),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _transcribe(BuildContext context, WidgetRef ref) async {
    final Result<void> done = await ref
        .read(recordAudioTranscriptionControllerProvider(entry.id).notifier)
        .transcribe();
    if (done case FailureResult<void>(
      :final Failure failure,
    ) when context.mounted) {
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
    }
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
    final LocalizedCopy localCopy = Copy.of(context);

    return switch (template) {
      AsyncData<TemplateDef?>(:final TemplateDef? value) => _loaded(
        context,
        value,
      ),
      AsyncError<TemplateDef?>(:final Object error) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSectionHeader(title: localCopy.recordSectionFields),
          AppErrorState(
            failure: Failure.from(error),
            onRetry: () =>
                ref.invalidate(recordEditTemplateProvider(entry.templateId)),
          ),
          // The labels could not be read; the values still show, by key.
          ..._tiles(context, _unlabelled()),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSectionHeader(title: localCopy.recordSectionFields),
          const AppSkeleton(count: 2),
        ],
      ),
    };
  }

  Widget _loaded(BuildContext context, TemplateDef? template) {
    final LocalizedCopy localCopy = Copy.of(context);

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
          title: localCopy.recordSectionFields,
          // An icon beside the heading fits at 200 percent text on a
          // phone, where a worded button would push the heading off.
          action: editable.isEmpty
              ? null
              : AppIconButton(
                  key: const ValueKey<String>('record-edit-fields'),
                  icon: AppIcons.edit,
                  tooltip: localCopy.recordValuesEditTitle,
                  semanticLabel: localCopy.recordValuesEditTitle,
                  onPressed: () => unawaited(context.push<void>(valuesRoute)),
                ),
        ),
        if (template == null) ...<Widget>[
          AppBanner(
            key: const ValueKey<String>('record-template-missing'),
            message: localCopy.recordTemplateMissingNotice,
            icon: AppIcons.template,
            tone: SnackTone.info,
          ),
          const SizedBox(height: Space.x2),
        ],
        if (live.isEmpty && retired.isEmpty)
          Text(
            localCopy.recordDetailNoValues,
            key: const ValueKey<String>('record-no-values'),
            style: AppText.body.copyWith(color: colors.onSurface),
          ),
        ..._tiles(context, live),
        if (retired.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x3),
          AppSectionHeader(
            title: localCopy.recordRetiredValuesTitle,
            dense: true,
          ),
          Text(
            localCopy.recordRetiredValuesMessage,
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
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordValue? value = row.value;
    final bool filled = value != null && value.hasValue;
    return AppListTile(
      key: ValueKey<String>('record-field-${row.fieldKey}'),
      title: row.label,
      subtitle: filled ? value.display : localCopy.recordFieldEmpty,
      dense: true,
      trailing: filled
          ? _ValueMarks(value: value, retired: row.retired)
          : row.retired
          ? AppStatusPill.badge(
              status: RecordStatus.archived,
              label: localCopy.recordValueRetired,
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
    final LocalizedCopy localCopy = Copy.of(context);

    final ValueSource source = value.valueSource;
    final String sourceLabel = _sourceLabel(
      source,
      localizedCopy: Copy.of(context),
    );
    // A value typed by a person has no band, whatever an earlier reading
    // scored; any other shows its stored band, else its score.
    final ConfidenceBand? band = ConfidenceBand.fromStored(value.band);
    final double? score = value.confidence;
    final bool banded =
        source != ValueSource.manual && (band != null || score != null);
    return Semantics(
      label: localCopy.recordValueMarks(
        source: sourceLabel,
        band: !banded ? '' : band?.label ?? localCopy.recordBandScore(score!),
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
              if (banded) ...<Widget>[
                const SizedBox(height: Space.x1),
                ConfidenceIndicator(
                  key: ValueKey<String>('record-band-${value.fieldKey}'),
                  band: band,
                  score: score,
                  compact: true,
                ),
              ],
              if (value.evidenceRemoved) ...<Widget>[
                const SizedBox(height: Space.x1),
                AppStatusPill.badge(
                  key: ValueKey<String>(
                    'record-evidence-removed-${value.fieldKey}',
                  ),
                  status: RecordStatus.needsReview,
                  label: localCopy.recordValueEvidenceRemoved,
                ),
              ],
              if (retired) ...<Widget>[
                const SizedBox(height: Space.x1),
                AppStatusPill.badge(
                  key: ValueKey<String>('record-retired-${value.fieldKey}'),
                  status: RecordStatus.archived,
                  label: localCopy.recordValueRetired,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Where a value came from, in the operator's words.
String _sourceLabel(ValueSource source, {LocalizedCopy? localizedCopy}) {
  return switch (source) {
    ValueSource.manual => (localizedCopy ?? Copy.english).recordSourceTyped,
    ValueSource.ocr => (localizedCopy ?? Copy.english).recordSourceOcr,
    ValueSource.aiVision => (localizedCopy ?? Copy.english).recordSourceAiPhoto,
    ValueSource.aiText => (localizedCopy ?? Copy.english).recordSourceAiText,
    ValueSource.stt => (localizedCopy ?? Copy.english).recordSourceSpeech,
    ValueSource.barcode => (localizedCopy ?? Copy.english).recordSourceBarcode,
    ValueSource.lookup => (localizedCopy ?? Copy.english).recordSourceLookup,
    ValueSource.context => (localizedCopy ?? Copy.english).recordSourceContext,
    ValueSource.auto => (localizedCopy ?? Copy.english).recordSourceDefault,
    ValueSource.import => (localizedCopy ?? Copy.english).recordSourceImported,
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
String _flagLabel(RecordFlag flag, {LocalizedCopy? localizedCopy}) {
  return switch (flag) {
    RecordFlag.hasPhotos =>
      (localizedCopy ?? Copy.english).recordsFlagHasPhotos,
    RecordFlag.hasDuplicate =>
      (localizedCopy ?? Copy.english).recordsFlagHasDuplicate,
    RecordFlag.hasConflict =>
      (localizedCopy ?? Copy.english).recordsFlagHasConflict,
    RecordFlag.hasVariance =>
      (localizedCopy ?? Copy.english).recordsFlagHasVariance,
    RecordFlag.evidenceRemoved =>
      (localizedCopy ?? Copy.english).recordsFlagEvidenceRemoved,
    RecordFlag.mergedFromBundle =>
      (localizedCopy ?? Copy.english).recordsFlagMerged,
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
    final LocalizedCopy localCopy = Copy.of(context);

    final List<MapEntry<String, String>> levels = <MapEntry<String, String>>[
      for (final MapEntry<String, String> level in entry.context.entries)
        if (level.value.trim().isNotEmpty) level,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: localCopy.recordDetailContextTitle),
        if (levels.isEmpty)
          Text(
            localCopy.recordDetailContextEmpty,
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
    final LocalizedCopy localCopy = Copy.of(context);

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
        AppSectionHeader(title: localCopy.recordDetailProvenanceTitle),
        for (final ValueSource source in ValueSource.values)
          if ((bySource[source] ?? 0) > 0)
            AppListTile(
              key: ValueKey<String>('record-provenance-${source.name}'),
              leading: Icon(_sourceIcon(source), color: icon),
              title: _sourceLabel(source, localizedCopy: Copy.of(context)),
              subtitle: localCopy.recordDetailValuesCount(bySource[source]!),
              dense: true,
            ),
        if (verified > 0)
          AppListTile(
            key: const ValueKey<String>('record-provenance-verified'),
            leading: Icon(AppIcons.verified, color: icon),
            title: localCopy.recordDetailVerified,
            subtitle: localCopy.recordDetailValuesCount(verified),
            dense: true,
          ),
        if (removed > 0)
          AppListTile(
            key: const ValueKey<String>('record-provenance-evidence'),
            leading: Icon(AppIcons.brokenFile, color: icon),
            title: localCopy.recordValueEvidenceRemoved,
            subtitle: localCopy.recordDetailValuesCount(removed),
            dense: true,
          ),
        if (readers.isNotEmpty)
          AppListTile(
            key: const ValueKey<String>('record-provenance-readers'),
            leading: Icon(AppIcons.ai, color: icon),
            title: localCopy.recordDetailReadBy,
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
    final LocalizedCopy localCopy = Copy.of(context);

    final DateTime? approvedAt = entry.approvedAt;
    final DateTime? exportedAt = entry.exportedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: localCopy.recordDetailDatesTitle),
        AppListTile(
          key: const ValueKey<String>('record-date-captured'),
          title: localCopy.recordDetailCaptured,
          subtitle: localCopy.recordDetailWhen(
            entry.capturedAt.toLocal(),
            by: entry.capturedBy,
          ),
          dense: true,
        ),
        AppListTile(
          key: const ValueKey<String>('record-date-updated'),
          title: localCopy.recordDetailUpdated,
          subtitle: localCopy.recordDetailWhen(entry.updatedAt.toLocal()),
          dense: true,
        ),
        if (approvedAt != null)
          AppListTile(
            key: const ValueKey<String>('record-date-approved'),
            title: localCopy.recordDetailApproved,
            subtitle: localCopy.recordDetailWhen(
              approvedAt.toLocal(),
              by: entry.approvedBy ?? '',
            ),
            dense: true,
          ),
        AppListTile(
          key: const ValueKey<String>('record-date-exported'),
          title: localCopy.recordDetailExported,
          subtitle: exportedAt == null
              ? localCopy.recordDetailNotExported
              : localCopy.recordDetailWhen(exportedAt.toLocal()),
          dense: true,
        ),
      ],
    );
  }
}
