import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/speech/finished_utterance.dart';
import 'package:tapture/core/speech/transcript_sink.dart';

import 'transcript.dart';
import 'transcript_start.dart';
import 'transcript_summary.dart';

/// The store of live transcripts, beside their audio (spec §30.4.6).
///
/// Raw segments are written once, contiguously, and read in time order;
/// the operator's edit is written beside them and audited. Every write is
/// durable before it reports success (rule 4).
abstract interface class TranscriptRepository {
  /// Creates a `live` transcript for [start], durably, before the
  /// microphone opens.
  Future<Result<TranscriptSummary>> begin(TranscriptStart start);

  /// Durably appends [utterance] to live transcript [transcriptId]: its
  /// segments, how far the audio is covered, and its range when skipped. A
  /// repeated segment with the same text is ignored; a gap or a different
  /// text fails with `StorageFailure` and writes nothing.
  Future<Result<void>> appendUtterance(
    String transcriptId,
    FinishedUtterance utterance,
  );

  /// The sink a session writes live transcript [transcriptId] through. Its
  /// `finish` completes the transcript, or marks it interrupted. A missing,
  /// discarded or finished transcript has no sink and fails.
  Future<Result<TranscriptSink>> sinkFor(String transcriptId);

  /// Links transcript [id] to the audio attachment [attachmentId]. Linking
  /// the same attachment again succeeds; a different one fails with
  /// `ValidationFailure`.
  Future<Result<void>> linkAttachment(String id, String attachmentId);

  /// Marks live transcript [id] complete over [duration] of audio, heard in
  /// [languageTag] by [modelId]. Repeating it on a transcript already
  /// complete with the same values succeeds.
  Future<Result<TranscriptSummary>> complete(
    String id, {
    required Duration duration,
    required String languageTag,
    String? modelId,
  });

  /// Marks live transcript [id] interrupted, over [duration] of audio when
  /// known.
  Future<Result<TranscriptSummary>> markInterrupted(
    String id, {
    Duration? duration,
  });

  /// Files [audio] of a standalone transcript [id] as a project attachment
  /// owned by no record, links it, and returns the attachment id.
  Future<Result<String>> fileStandaloneAudio(String id, AudioRecording audio);

  /// Removes transcript [id] from every list with a tombstone; its rows and
  /// audio are kept.
  Future<Result<void>> discard(String id);

  /// Renames transcript [id] to [title], audited for [operator].
  Future<Result<TranscriptSummary>> rename(
    String id,
    String title, {
    String? operator,
  });

  /// Writes [text] beside the raw segments of transcript [id], audited for
  /// [operator]. Text identical to the raw text clears the edit. A live
  /// transcript refuses with `ValidationFailure`.
  Future<Result<Transcript>> saveEdit(
    String id,
    String text, {
    String? operator,
  });

  /// Clears the edit of transcript [id], audited for [operator]. A live
  /// transcript refuses with `ValidationFailure`.
  Future<Result<Transcript>> clearEdit(String id, {String? operator});

  /// Turns complete or interrupted transcript [id] live again so the rest
  /// of its audio can be transcribed. Its sink's `finish` makes it complete
  /// when the rest was covered, and otherwise restores its earlier status.
  Future<Result<void>> reopenForRemaining(String id);

  /// Transcript [id], or null when it is missing or discarded.
  Future<Result<Transcript?>> read(String id);

  /// Transcript [id] after every write; null when missing or discarded.
  Stream<Transcript?> watch(String id);

  /// Transcripts of project [projectId] (every project when null), newest
  /// first, at most [limit]. A non-empty [query] matches the title, the
  /// edit or any raw segment, case-insensitively and literally.
  Stream<List<TranscriptSummary>> watchProject(
    String? projectId, {
    String query = '',
    int limit = AppConstants.listPageSize,
  });

  /// Transcripts heard from audio filed on record [recordId], newest first.
  Stream<List<TranscriptSummary>> watchRecord(String recordId);

  /// Transcripts of meeting [meetingId], newest first.
  Stream<List<TranscriptSummary>> watchMeeting(String meetingId);

  /// The newest complete transcript heard from [attachmentId], or null.
  Future<Result<TranscriptSummary?>> completedForAttachment(
    String attachmentId,
  );

  /// Transcripts still `live`. At launch no session is running, so each is
  /// one a closed app left behind.
  Future<Result<List<TranscriptSummary>>> stale();
}
