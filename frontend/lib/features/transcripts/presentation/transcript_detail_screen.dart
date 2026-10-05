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
import 'package:tapture/core/security/untrusted_text.dart';
import 'package:tapture/core/speech/speech_readiness_notifier.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/feedback/show_app_text_prompt.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import '../domain/transcript.dart';
import '../domain/transcript_status.dart';
import '../domain/transcript_summary.dart';
import 'transcript_detail_controller.dart';
import 'transcript_detail_status.dart';
import 'transcript_editor.dart';
import 'transcript_providers.dart';
import 'transcript_tile.dart';

/// One transcript (spec §30.4.6): its text, edited beside the raw segments,
/// which are never changed; going back to the original and renaming, both
/// audited; and **Finish the transcript** whenever part of the recording
/// is left untranscribed and on-device speech is ready.
///
/// While the transcript is still being written it is read-only. Leaving
/// with an unsaved edit asks first.
class TranscriptDetailScreen extends ConsumerWidget {
  /// The page of transcript [transcriptId], opened inside project
  /// [projectId] or, when null, from the transcripts across projects.
  const TranscriptDetailScreen({
    required this.transcriptId,
    this.projectId,
    super.key,
  });

  /// The transcript shown.
  final String transcriptId;

  /// The project branch the page was opened in, or null.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);
    final AsyncValue<Transcript?> watched = ref.watch(
      transcriptProvider(transcriptId),
    );
    final TranscriptDetailStatus status = ref.watch(
      transcriptDetailControllerProvider(transcriptId),
    );
    final Transcript? transcript = watched.value;
    final TranscriptSummary? summary = transcript?.summary;
    final String? draft = status.draft;
    // The unsaved edit, when it differs from what the transcript reads as.
    final String? edit = transcript != null && draft != transcript.displayText
        ? draft
        : null;
    final bool dirty = edit != null;
    final bool settled = summary?.status.settled ?? false;
    return PopScope<Object?>(
      canPop: !dirty,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) {
          unawaited(_confirmLeave(context, ref));
        }
      },
      child: AppPage(
        key: const ValueKey<String>('route-transcript'),
        title: summary == null
            ? localCopy.transcriptDetailTitle
            : _titleOf(localCopy, summary),
        subtitle: summary == null
            ? null
            : localCopy.liveTranscriptRow(summary.startedAt, ''),
        overflow: <AppOverflowAction>[
          if (summary != null)
            AppOverflowAction(
              key: const ValueKey<String>('transcript-rename'),
              label: localCopy.transcriptRename,
              icon: AppIcons.edit,
              onTap: () => unawaited(_rename(context, ref, summary)),
            ),
          if (settled && transcript?.editedText != null)
            AppOverflowAction(
              key: const ValueKey<String>('transcript-revert'),
              label: localCopy.transcriptRevert,
              icon: AppIcons.undo,
              onTap: () => unawaited(_revert(context, ref)),
            ),
        ],
        footer: settled
            ? AppPrimaryAction(
                key: const ValueKey<String>('transcript-save'),
                label: localCopy.transcriptSaveEdit,
                busy: status.saving,
                onPressed: edit != null && !status.saving
                    ? () => unawaited(_save(context, ref, edit))
                    : null,
              )
            : null,
        body: AsyncValueView<Transcript?>(
          value: watched,
          onRetry: () => ref.invalidate(transcriptProvider(transcriptId)),
          loadingShape: SkeletonShape.detail,
          loadingCount: 1,
          isEmpty: (Transcript? found) => found == null,
          empty: () => AppEmptyState(
            icon: AppIcons.transcript,
            headline: localCopy.transcriptMissing,
            message: localCopy.transcriptMissingMessage,
            actionLabel: localCopy.transcriptsTitle,
            onAction: () => context.go(_list()),
          ),
          data: (Transcript? found) => found == null
              ? const SizedBox.shrink()
              : _TranscriptBody(
                  transcript: found,
                  status: status,
                  // A finish rewrites what the field shows, so an unsaved
                  // edit is saved or dropped first.
                  onFinish: dirty
                      ? null
                      : () => unawaited(_finish(context, ref)),
                ),
        ),
      ),
    );
  }

  String _list() {
    final String? named = projectId;
    return named == null
        ? RoutePaths.transcripts
        : RoutePaths.projectTranscripts(named);
  }

  TranscriptDetailController _controller(WidgetRef ref) =>
      ref.read(transcriptDetailControllerProvider(transcriptId).notifier);

  Future<void> _save(BuildContext context, WidgetRef ref, String text) async {
    final LocalizedCopy localCopy = Copy.of(context);
    final Result<Transcript> saved = await _controller(ref).save(text);
    if (!context.mounted) {
      return;
    }
    _report(context, saved, localCopy.transcriptEditSaved);
  }

  Future<void> _revert(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.transcriptRevertTitle,
      message: localCopy.transcriptRevertMessage,
      confirmLabel: localCopy.transcriptRevertConfirm,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final Result<Transcript> reverted = await _controller(ref).revert();
    if (!context.mounted) {
      return;
    }
    _report(context, reverted, localCopy.transcriptReverted);
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    TranscriptSummary summary,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);
    final String? title = await showAppTextPrompt(
      context,
      title: localCopy.transcriptRename,
      label: localCopy.transcriptTitleLabel,
      initialValue: summary.title,
      validate: (String _) async => const Success<void>(null),
    );
    if (title == null || title.trim() == summary.title) {
      return;
    }
    final Result<TranscriptSummary> renamed = await _controller(
      ref,
    ).rename(title);
    if (!context.mounted) {
      return;
    }
    if (renamed case FailureResult<TranscriptSummary>(:final Failure failure)) {
      showAppSnack(
        context,
        localCopy.failureMessage(failure),
        tone: SnackTone.error,
      );
    }
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);
    final Result<void> finished = await _controller(ref).finish();
    if (!context.mounted) {
      return;
    }
    _report(context, finished, localCopy.transcriptFinished);
  }

  /// Asks before an unsaved edit is left behind; the edit is dropped only
  /// when the operator agrees.
  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final bool discard = await showAppConfirm(
      context,
      title: localCopy.discardChangesTitle,
      message: localCopy.unsavedChanges,
      confirmLabel: localCopy.discard,
      destructive: true,
    );
    if (!discard || !context.mounted) {
      return;
    }
    _controller(ref).dropDraft();
    navigator.pop();
  }

  static void _report<T>(BuildContext context, Result<T> result, String done) {
    final LocalizedCopy localCopy = Copy.of(context);
    switch (result) {
      case Success<T>():
        showAppSnack(context, done, tone: SnackTone.success);
      case FailureResult<T>(:final Failure failure):
        showAppSnack(
          context,
          localCopy.failureMessage(failure),
          tone: SnackTone.error,
        );
    }
  }

  static String _titleOf(LocalizedCopy localCopy, TranscriptSummary summary) {
    return summary.title.isEmpty
        ? localCopy.liveTranscriptUntitled
        : UntrustedText(summary.title).forDisplay();
  }
}

/// The transcript's notices, facts and text.
class _TranscriptBody extends ConsumerWidget {
  const _TranscriptBody({
    required this.transcript,
    required this.status,
    required this.onFinish,
  });

  final Transcript transcript;
  final TranscriptDetailStatus status;

  /// Null while an unsaved edit would be overwritten by the finish.
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);
    final TranscriptSummary summary = transcript.summary;
    final bool settled = summary.status.settled;
    final bool canFinish = ref.watch(speechReadinessProvider).ready;
    final Duration? length = summary.duration;
    final TextStyle caption = AppText.caption.copyWith(
      color: context.colors.onSurface,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!settled)
          _spaced(
            AppBanner(
              key: const ValueKey<String>('transcript-live'),
              message: localCopy.transcriptStillRecording,
              icon: AppIcons.info,
              tone: SnackTone.info,
            ),
          ),
        if (summary.status == TranscriptStatus.interrupted)
          _spaced(
            AppBanner(
              key: const ValueKey<String>('transcript-interrupted'),
              message: localCopy.transcriptStatusInterrupted,
              icon: AppIcons.warning,
              tone: SnackTone.warning,
            ),
          ),
        if (settled && summary.remaining)
          _spaced(
            _RemainingNotice(
              parts: _remainingParts(summary),
              canFinish: canFinish,
              finishing: status.finishing,
              onFinish: onFinish,
            ),
          ),
        _spaced(
          AppChipRow(
            chips: <AppChip>[
              AppChip(
                icon: AppIcons.offline,
                label: localCopy.speechOfflineBadge,
              ),
              AppChip(
                label: TranscriptTile.originLabel(localCopy, summary.ownerKind),
              ),
              if (summary.languageTag.isNotEmpty)
                AppChip(
                  label: localCopy.transcriptLanguage(summary.languageTag),
                ),
              if (summary.modelId.isNotEmpty)
                AppChip(label: localCopy.transcriptModel(summary.modelId)),
            ],
          ),
        ),
        if (length != null)
          _spaced(Text(localCopy.transcriptAudioLength(length), style: caption))
        else if (settled && summary.attachmentId == null)
          _spaced(Text(localCopy.transcriptNoAudio, style: caption)),
        TranscriptEditor(
          transcript: transcript,
          readOnly: !settled || status.saving,
          onChanged: ref
              .read(transcriptDetailControllerProvider(summary.id).notifier)
              .edit,
        ),
      ],
    );
  }

  /// How many parts are left: each gap, and the audio past the covered
  /// point.
  static int _remainingParts(TranscriptSummary summary) {
    final Duration? length = summary.duration;
    final bool tail =
        length != null && summary.coveredMs < length.inMilliseconds;
    return summary.gaps.length + (tail ? 1 : 0);
  }

  static Widget _spaced(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: child,
    );
  }
}

/// What is left to transcribe, and the control that finishes it on this
/// device when speech is ready.
class _RemainingNotice extends StatelessWidget {
  const _RemainingNotice({
    required this.parts,
    required this.canFinish,
    required this.finishing,
    required this.onFinish,
  });

  final int parts;
  final bool canFinish;
  final bool finishing;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);
    return AppCard(
      key: const ValueKey<String>('transcript-remaining'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            localCopy.transcriptGaps(parts),
            style: AppText.body.copyWith(color: context.colors.onSurface),
          ),
          if (canFinish) ...<Widget>[
            const SizedBox(height: Space.x2),
            AppButton(
              key: const ValueKey<String>('transcript-finish'),
              label: localCopy.transcriptFinish,
              icon: AppIcons.transcript,
              variant: AppButtonVariant.secondary,
              busy: finishing,
              onPressed: finishing ? null : onFinish,
            ),
          ],
        ],
      ),
    );
  }
}
