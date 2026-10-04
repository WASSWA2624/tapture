import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/audio/capture_pause_reason.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/speech/transcription_warning_kind.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_recording_bar.dart';
import 'package:tapture/core/widgets/app_recording_phase.dart';
import 'package:tapture/core/widgets/app_transcript_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import 'live_transcript_controller.dart';
import 'live_transcript_frame.dart';
import 'live_transcript_status.dart';
import 'transcript_mode.dart';
import 'transcript_providers.dart';
import 'transcript_session_phase.dart';
import 'transcript_session_target.dart';

/// One surface's live transcript: notices, the recording bar and the
/// words as they are heard, over the session [target] names
/// (FE-CONS-01).
///
/// Pause reasons and warnings are shown as they happen; a recording paused
/// in the background resumes only when the operator taps resume. Discard
/// asks first. With [showIdleControls] false the panel shows nothing until
/// a session starts, for a surface that starts it from its own control.
/// With [fill] the transcript takes the height left in a bounded parent.
class LiveTranscriptPanel extends ConsumerWidget {
  /// A panel over [target]'s session, starting it with [startLabel].
  /// [onOpenTranscript] opens the saved transcript by id; without it no
  /// open control is shown.
  const LiveTranscriptPanel({
    required this.target,
    this.startLabel,
    this.showIdleControls = true,
    this.fill = false,
    this.onOpenTranscript,
    super.key,
  });

  /// The session this panel shows and controls.
  final TranscriptSessionTarget target;

  /// Label of the start control. Defaults to the live transcript start.
  final String? startLabel;

  /// Whether the start control shows before a session starts.
  final bool showIdleControls;

  /// Whether the transcript fills the height of a bounded parent.
  final bool fill;

  /// Opens a saved transcript by its id.
  final ValueChanged<String>? onOpenTranscript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);
    final LiveTranscriptStatus status = ref.watch(
      liveTranscriptControllerProvider(target.sessionKey),
    );
    final LiveTranscriptController controller = ref.watch(
      liveTranscriptControllerProvider(target.sessionKey).notifier,
    );
    final TranscriptSessionPhase phase = status.phase;
    if (phase == TranscriptSessionPhase.idle && !showIdleControls) {
      return const SizedBox.shrink();
    }
    final bool canStart =
        phase == TranscriptSessionPhase.idle ||
        phase == TranscriptSessionPhase.saved ||
        (phase == TranscriptSessionPhase.failed && !status.retryable);
    final List<Widget> notices = _notices(localCopy, status);
    final String? transcriptId = status.transcriptId;
    final ValueChanged<String>? open = onOpenTranscript;
    final Widget transcript = ValueListenableBuilder<LiveTranscriptFrame>(
      valueListenable: controller.frames,
      builder: (BuildContext context, LiveTranscriptFrame frame, Widget? _) {
        return AppTranscriptView(
          paragraphs: frame.paragraphs,
          tentative: frame.tentative,
          live:
              phase == TranscriptSessionPhase.recording ||
              phase == TranscriptSessionPhase.paused ||
              phase == TranscriptSessionPhase.finishing ||
              status.draining,
        );
      },
    );
    return Column(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Widget notice in notices) ...<Widget>[
          notice,
          const SizedBox(height: Space.x2),
        ],
        ValueListenableBuilder<LiveTranscriptFrame>(
          valueListenable: controller.frames,
          builder: (BuildContext context, LiveTranscriptFrame frame, Widget? _) {
            return AppRecordingBar(
              phase: _barPhase(phase),
              elapsed: frame.elapsed,
              level: frame.level,
              status: _barStatus(localCopy, status),
              startLabel: startLabel,
              onStart: canStart
                  ? () => unawaited(controller.start(target))
                  : null,
              onPause: () => unawaited(controller.pause()),
              onResume: () => unawaited(controller.resume()),
              onStop: () => unawaited(controller.stop()),
              onCancel: () => unawaited(_confirmDiscard(context, controller)),
            );
          },
        ),
        if (status.mode == TranscriptMode.live) ...<Widget>[
          const SizedBox(height: Space.x2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppChip(
              icon: AppIcons.offline,
              label: localCopy.speechOfflineBadge,
            ),
          ),
        ],
        if (phase == TranscriptSessionPhase.failed && status.retryable) ...<
          Widget
        >[
          const SizedBox(height: Space.x2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              key: const ValueKey<String>('live-transcript-retry'),
              label: localCopy.liveTranscriptRetrySave,
              variant: AppButtonVariant.secondary,
              onPressed: () => unawaited(controller.retrySave()),
            ),
          ),
        ],
        const SizedBox(height: Space.x3),
        if (fill) Expanded(child: transcript) else transcript,
        if (phase == TranscriptSessionPhase.saved &&
            transcriptId != null &&
            open != null) ...<Widget>[
          const SizedBox(height: Space.x3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              key: const ValueKey<String>('live-transcript-open'),
              label: localCopy.liveTranscriptOpen,
              icon: AppIcons.transcript,
              variant: AppButtonVariant.secondary,
              onPressed: () => open(transcriptId),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDiscard(
    BuildContext context,
    LiveTranscriptController controller,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.liveTranscriptCancelTitle,
      message: localCopy.liveTranscriptCancelMessage,
      confirmLabel: localCopy.liveTranscriptCancel,
      destructive: true,
    );
    if (confirmed) {
      await controller.discard();
    }
  }

  static AppRecordingPhase _barPhase(TranscriptSessionPhase phase) {
    return switch (phase) {
      TranscriptSessionPhase.starting => AppRecordingPhase.starting,
      TranscriptSessionPhase.recording => AppRecordingPhase.recording,
      TranscriptSessionPhase.paused => AppRecordingPhase.paused,
      TranscriptSessionPhase.finishing => AppRecordingPhase.finishing,
      TranscriptSessionPhase.idle ||
      TranscriptSessionPhase.saved ||
      TranscriptSessionPhase.failed => AppRecordingPhase.idle,
    };
  }

  /// The bar's status where the phase's own label does not say enough: why
  /// it paused, that it records without a transcript, or that it is saved.
  static String? _barStatus(
    LocalizedCopy localCopy,
    LiveTranscriptStatus status,
  ) {
    switch (status.phase) {
      case TranscriptSessionPhase.paused:
        return switch (status.pauseReason) {
          CapturePauseReason.background =>
            localCopy.liveTranscriptStatusPausedBackground,
          CapturePauseReason.interruption =>
            localCopy.liveTranscriptStatusPausedInterruption,
          CapturePauseReason.microphoneLost => localCopy.liveTranscriptMicLost,
          CapturePauseReason.permissionRevoked =>
            localCopy.liveTranscriptPermissionRevoked,
          CapturePauseReason.user || null => null,
        };
      case TranscriptSessionPhase.recording:
        final bool recordOnly =
            status.mode == TranscriptMode.audioOnly ||
            status.warning == TranscriptionWarningKind.transcriptionUnavailable;
        return recordOnly ? localCopy.audioRecorderStatus('recording') : null;
      case TranscriptSessionPhase.saved:
        return status.draining
            ? localCopy.liveTranscriptStatusDraining
            : localCopy.liveTranscriptStatusSaved;
      case TranscriptSessionPhase.idle:
      case TranscriptSessionPhase.starting:
      case TranscriptSessionPhase.finishing:
      case TranscriptSessionPhase.failed:
        return null;
    }
  }

  /// Banners for a failure, unsaved text and the latest warning.
  static List<Widget> _notices(
    LocalizedCopy localCopy,
    LiveTranscriptStatus status,
  ) {
    final Failure? failure = status.failure;
    final String? warning = _warningText(localCopy, status);
    final bool audioOnly =
        status.mode == TranscriptMode.audioOnly &&
        status.warning != TranscriptionWarningKind.transcriptionUnavailable;
    return <Widget>[
      if (failure != null)
        AppBanner(
          key: const ValueKey<String>('live-transcript-failure'),
          message: localCopy.failureMessage(failure),
          icon: AppIcons.error,
          tone: SnackTone.error,
        ),
      if (audioOnly)
        AppBanner(
          key: const ValueKey<String>('live-transcript-audio-only'),
          message: localCopy.liveTranscriptAudioOnly,
          icon: AppIcons.info,
          tone: SnackTone.info,
        ),
      if (status.unsaved)
        AppBanner(
          key: const ValueKey<String>('live-transcript-unsaved'),
          message: localCopy.liveTranscriptUnsaved,
          icon: AppIcons.warning,
          tone: SnackTone.warning,
        ),
      if (warning != null)
        AppBanner(
          key: const ValueKey<String>('live-transcript-warning'),
          message: warning,
          icon: AppIcons.warning,
          tone: SnackTone.warning,
        ),
    ];
  }

  static String? _warningText(
    LocalizedCopy localCopy,
    LiveTranscriptStatus status,
  ) {
    return switch (status.warning) {
      null || TranscriptionWarningKind.transcriptUnsaved => null,
      TranscriptionWarningKind.transcriptionUnavailable =>
        localCopy.liveTranscriptAudioOnly,
      TranscriptionWarningKind.engineBehind => localCopy.liveTranscriptBehind(
        status.lag?.inMinutes ?? 0,
      ),
      TranscriptionWarningKind.utteranceSkipped =>
        localCopy.liveTranscriptUtteranceSkipped,
      TranscriptionWarningKind.storageLow => localCopy.liveTranscriptStorageLow,
      TranscriptionWarningKind.storageStop =>
        localCopy.liveTranscriptStorageStop,
      TranscriptionWarningKind.sessionLimit =>
        localCopy.liveTranscriptSessionLimit,
    };
  }
}
