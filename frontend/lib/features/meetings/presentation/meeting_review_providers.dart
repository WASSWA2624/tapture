import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/speech/speech_readiness.dart';
import 'package:tapture/core/speech/speech_readiness_notifier.dart';
import 'package:tapture/features/transcripts/transcripts.dart'
    show
        LiveTranscriptKey,
        TranscriptMode,
        TranscriptOwnerKind,
        TranscriptSessionTarget;

import '../domain/meeting_attachment.dart';
import '../domain/meeting_repository.dart';
import '../meetings.dart' show meetingRepositoryProvider;

/// The meeting `meetingId` as stored, for a review page opened by its id;
/// null when it is not on this device.
final meetingRecordProvider = FutureProvider.autoDispose
    .family<MeetingRecord?, String>((Ref ref, String meetingId) async {
      return (await ref.watch(meetingRepositoryProvider).read(meetingId))
          .getOrThrow();
    }, retry: (int _, Object _) => null);

/// Where meeting `meetingId` of project `projectId` records: a take at
/// `storagePathFor(meetingId, 'recording.wav')`, filed on the meeting
/// through `attachStored` once it is published.
///
/// It transcribes while a speech model is ready, and otherwise records the
/// audio only, so the meeting is never kept from recording (Rule 3). The
/// session outlives the page until its take is filed.
final meetingTranscriptTargetProvider = Provider.autoDispose
    .family<TranscriptSessionTarget, ({String meetingId, String projectId})>((
      Ref ref,
      ({String meetingId, String projectId}) meeting,
    ) {
      final MeetingRepository meetings = ref.watch(meetingRepositoryProvider);
      final bool ready = ref.watch(
        speechReadinessProvider.select(
          (SpeechReadiness readiness) => readiness.ready,
        ),
      );
      final String meetingId = meeting.meetingId;
      return TranscriptSessionTarget(
        sessionKey: LiveTranscriptKey.meeting(meetingId),
        projectId: meeting.projectId,
        ownerKind: TranscriptOwnerKind.meeting,
        ownerId: meetingId,
        audioPath: () => meetings.storagePathFor(meetingId, _recordingName),
        fileAudio: (AudioRecording audio) async {
          final Result<MeetingAttachment> filed = await meetings.attachStored(
            meetingId,
            storagePath: audio.relativePath,
            mimeType: audio.mimeType,
            bytes: audio.byteLength,
            sha256: audio.sha256,
            duration: audio.duration,
          );
          return filed.map<String?>((MeetingAttachment file) => file.id);
        },
        mode: ready ? TranscriptMode.live : TranscriptMode.audioOnly,
      );
    });

/// The file name a meeting's take is published as.
const String _recordingName = 'recording.wav';
