import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/projects.dart'
    show Project, projectByIdProvider;

import '../domain/transcript.dart';
import '../domain/transcript_owner_kind.dart';
import '../domain/transcript_repository.dart';
import '../domain/transcript_start.dart';
import '../domain/transcript_summary.dart';
import '../transcripts.dart' show transcriptRepositoryProvider;
import 'live_transcript_controller.dart';
import 'live_transcript_key.dart';
import 'live_transcript_status.dart';
import 'record_audio_transcription_controller.dart';
import 'transcript_detail_controller.dart';
import 'transcript_detail_status.dart';
import 'transcript_session_target.dart';

/// When a live transcript starts, for its row. Tests override it.
final Provider<Clock> transcriptClockProvider = Provider<Clock>((Ref _) {
  return const SystemClock();
});

/// Names the takes the Transcribe screen records. Tests override it.
final Provider<IdService> transcriptIdsProvider = Provider<IdService>((
  Ref ref,
) {
  return UuidV7Service(ref.watch(transcriptClockProvider));
});

/// The live transcript session held under a session key
/// (`LiveTranscriptKey`). Disposed with its last listener unless a running
/// session's target keeps it alive until its take is filed.
final liveTranscriptControllerProvider = NotifierProvider.autoDispose
    .family<LiveTranscriptController, LiveTranscriptStatus, String>(
      LiveTranscriptController.new,
    );

/// Transcripts heard from audio filed on a record, by record id, newest
/// first.
final recordTranscriptsProvider = StreamProvider.autoDispose
    .family<List<TranscriptSummary>, String>((Ref ref, String recordId) {
      return ref.watch(transcriptRepositoryProvider).watchRecord(recordId);
    });

/// The audio clips filed on a record that no transcript was heard from, by
/// record id, each as the transcript it would begin.
final recordUntranscribedAudioProvider = StreamProvider.autoDispose
    .family<List<TranscriptStart>, String>((Ref ref, String recordId) {
      return ref
          .watch(transcriptRepositoryProvider)
          .watchUntranscribedAudio(recordId);
    });

/// Whether a record's audio is being transcribed on this device, by record
/// id, and the intent that starts it.
final recordAudioTranscriptionControllerProvider = NotifierProvider.autoDispose
    .family<RecordAudioTranscriptionController, bool, String>(
      RecordAudioTranscriptionController.new,
    );

/// Transcripts of a meeting, by meeting id, newest first.
final meetingTranscriptsProvider = StreamProvider.autoDispose
    .family<List<TranscriptSummary>, String>((Ref ref, String meetingId) {
      return ref.watch(transcriptRepositoryProvider).watchMeeting(meetingId);
    });

/// The transcript history: the newest `limit` transcripts of a project
/// (every project when `projectId` is null) matching `query`, kept current.
/// The list asks for a longer page as the operator nears its end.
final transcriptHistoryProvider = StreamProvider.autoDispose
    .family<
      List<TranscriptSummary>,
      ({String? projectId, String query, int limit})
    >((Ref ref, ({String? projectId, String query, int limit}) page) {
      return ref
          .watch(transcriptRepositoryProvider)
          .watchProject(page.projectId, query: page.query, limit: page.limit);
    }, retry: (int _, Object _) => null);

/// One transcript, by id, after every write; null once it is missing or
/// discarded.
final transcriptProvider = StreamProvider.autoDispose
    .family<Transcript?, String>((Ref ref, String transcriptId) {
      return ref.watch(transcriptRepositoryProvider).watch(transcriptId);
    }, retry: (int _, Object _) => null);

/// A transcript page's edit and the work in flight, by transcript id.
final transcriptDetailControllerProvider = NotifierProvider.autoDispose
    .family<TranscriptDetailController, TranscriptDetailStatus, String>(
      TranscriptDetailController.new,
    );

/// Where the Transcribe screen of project `projectId` records: a standalone
/// transcript whose take is `projects/<folder>/audio/<id>.wav`, filed as a
/// project attachment owned by no record. Null until the project is read.
///
/// The take is filed against the transcript row the session began; its id
/// is followed from the session's status, so filing still knows it after
/// the screen is gone.
final standaloneTranscriptTargetProvider = Provider.autoDispose
    .family<TranscriptSessionTarget?, String>((Ref ref, String projectId) {
      final Project? project = ref.watch(projectByIdProvider(projectId)).value;
      if (project == null) {
        return null;
      }
      final TranscriptRepository repository = ref.watch(
        transcriptRepositoryProvider,
      );
      final IdService ids = ref.watch(transcriptIdsProvider);
      final String sessionKey = LiveTranscriptKey.standalone(projectId);
      String? transcriptId = ref
          .read(liveTranscriptControllerProvider(sessionKey))
          .transcriptId;
      ref.listen<LiveTranscriptStatus>(
        liveTranscriptControllerProvider(sessionKey),
        (LiveTranscriptStatus? _, LiveTranscriptStatus next) {
          final String? started = next.transcriptId;
          if (started != null) {
            transcriptId = started;
          }
        },
      );
      final String folder = project.folderName;
      return TranscriptSessionTarget(
        sessionKey: sessionKey,
        projectId: projectId,
        ownerKind: TranscriptOwnerKind.standalone,
        audioPath: () async => Success<String>(
          '${EvidencePurge.projectsFolder}/$folder/$_audioFolder/'
          '${ids.newId()}$_takeExtension',
        ),
        fileAudio: (AudioRecording audio) async {
          final String? id = transcriptId;
          if (id == null) {
            return const FailureResult<String?>(ValidationFailure());
          }
          final Result<String> filed = await repository.fileStandaloneAudio(
            id,
            audio,
          );
          return filed.map<String?>((String attachmentId) => attachmentId);
        },
      );
    });

/// The project folder Transcribe takes are published under.
const String _audioFolder = 'audio';

/// The extension of a published take.
const String _takeExtension = '.wav';
