import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/speech/speech_readiness.dart';
import 'package:tapture/core/speech/speech_readiness_notifier.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/transcripts/transcripts.dart'
    show
        LiveTranscriptPanel,
        LiveTranscriptStatus,
        TranscriptSessionPhase,
        TranscriptSessionTarget,
        TranscriptSummary,
        liveTranscriptControllerProvider,
        meetingTranscriptsProvider;

import '../domain/meeting_transcription.dart';
import 'meeting_audio_section.dart';
import 'meeting_review_providers.dart';

/// Records a meeting and writes down what is said as it is said, on this
/// device (spec §30.4.5), above every transcript the meeting already has.
///
/// Without a ready speech model the meeting records its audio only, and
/// says so. A browser that cannot capture audio says that instead of
/// offering to record. The take is filed on the meeting when it stops; a
/// saved transcript opens in the transcript editor.
class MeetingLiveSection extends ConsumerWidget {
  /// The recorder of meeting [meetingId] on project [projectId], listing
  /// the meeting's on-device transcripts and then its older online
  /// transcription [versions]. [isWeb] is the test seam for the browser.
  const MeetingLiveSection({
    required this.meetingId,
    required this.projectId,
    this.versions = const <TranscriptVersion>[],
    this.isWeb = kIsWeb,
    super.key,
  });

  /// The meeting recorded.
  final String meetingId;

  /// The project the meeting is filed on.
  final String projectId;

  /// Older online transcription runs, shown read-only after the rest.
  final List<TranscriptVersion> versions;

  /// Whether this runs in a browser.
  final bool isWeb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);
    final TranscriptSessionTarget target = ref.watch(
      meetingTranscriptTargetProvider((
        meetingId: meetingId,
        projectId: projectId,
      )),
    );
    final LiveTranscriptStatus status = ref.watch(
      liveTranscriptControllerProvider(target.sessionKey),
    );
    final bool checked = ref.watch(
      speechReadinessProvider.select(
        (SpeechReadiness readiness) => readiness.verdict != null,
      ),
    );
    final List<TranscriptSummary> transcripts =
        ref.watch(meetingTranscriptsProvider(meetingId)).value ??
        const <TranscriptSummary>[];
    final bool idle = status.phase == TranscriptSessionPhase.idle;
    final Widget recorder;
    if (isWeb && _cannotCapture(status)) {
      recorder = AppBanner(
        key: const ValueKey<String>('meeting-capture-unavailable'),
        message: localCopy.audioRecorderUnavailable,
        icon: AppIcons.info,
        tone: SnackTone.info,
      );
    } else if (idle && !checked) {
      // Until readiness is known the target cannot say how it will record.
      recorder = const AppSkeleton(shape: SkeletonShape.detail, count: 1);
    } else {
      recorder = LiveTranscriptPanel(
        target: target,
        startLabel: localCopy.meetingRecord,
        onOpenTranscript: (String transcriptId) => _open(context, transcriptId),
      );
    }
    return MeetingAudioSection(
      recorder: recorder,
      transcripts: transcripts,
      versions: versions,
      onOpenTranscript: (TranscriptSummary transcript) =>
          _open(context, transcript.id),
    );
  }

  void _open(BuildContext context, String transcriptId) {
    unawaited(
      context.push(RoutePaths.projectTranscript(projectId, transcriptId)),
    );
  }

  /// Whether the session could not start because this browser has no
  /// audio capture: the microphone never opened, and trying again cannot
  /// open it.
  static bool _cannotCapture(LiveTranscriptStatus status) {
    final Failure? failure = status.failure;
    return status.phase == TranscriptSessionPhase.failed &&
        !status.retryable &&
        failure is ProviderFailure &&
        failure.kind == ProviderFailureKind.unavailable;
  }
}
