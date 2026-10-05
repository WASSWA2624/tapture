import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/pending_audio_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/transcripts/transcripts.dart'
    show LiveTranscriptKey, TranscriptOwnerKind, TranscriptSessionTarget;

/// Where the caption recorder of capture session `sessionKey` records and
/// transcribes a take (task 125), given the take it stages.
///
/// The target stages [PendingAudioDraft] before the transcript row and the
/// microphone, so the take is owned durably before a byte is written
/// (rule 4). Stopping files the published take through
/// [CaptureController.publishAudio], as the plain recorder does, under the
/// take's id, which becomes its attachment id. Discarding forgets the
/// pending take and keeps its file. The session is not kept alive past the
/// page: leaving it stops and files the take.
final captureTranscriptTargetProvider = Provider.autoDispose
    .family<TranscriptSessionTarget Function(PendingAudioDraft take), String>((
      Ref ref,
      String sessionKey,
    ) {
      final CaptureController capture = ref.watch(
        captureControllerProvider(sessionKey).notifier,
      );
      return (PendingAudioDraft take) => TranscriptSessionTarget(
        sessionKey: LiveTranscriptKey.capture(sessionKey),
        projectId: take.projectId,
        ownerKind: TranscriptOwnerKind.capture,
        audioPath: () async => Success<String>(take.storageRelativePath),
        beforeStart: () => capture.stageAudio(take),
        fileAudio: (AudioRecording audio) async {
          final Result<void> published = await capture.publishAudio(audio);
          return published.map<String?>((void _) => take.id);
        },
        onDiscard: () async {
          await capture.dropAudio(take.id);
        },
        keepAlive: false,
      );
    });
