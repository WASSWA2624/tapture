import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/logger.dart';

import '../domain/transcript_owner_kind.dart';
import '../domain/transcript_repository.dart';
import '../domain/transcript_summary.dart';

/// Settles the transcripts a closed app left `live`, once at launch, after
/// merge recovery and before any session can start (spec §30.4.6).
///
/// A capture transcript is only marked interrupted: the capture recovers
/// and files its own take. A meeting or standalone transcript gets its take
/// recovered (adopted or repaired), filed and linked first. No file is ever
/// deleted, and only counts are logged.
final class TranscriptRecovery {
  /// Recovery over `repository`, logging through [logger].
  TranscriptRecovery({required this._repository, Logger? logger})
    : _log = logger;

  final TranscriptRepository _repository;
  final Logger? _log;

  Logger get _logger => _log ?? Logger.current;

  /// Marks every stale transcript interrupted and returns how many were.
  ///
  /// [recoverAudio] publishes the take at a storage path, or returns null
  /// when nothing was recorded. [fileAudio] files a recovered take for its
  /// transcript's owner and returns the attachment id. A take that cannot
  /// be recovered or filed leaves the transcript interrupted without it.
  Future<Result<int>> run({
    required Future<Result<AudioRecording?>> Function(String storagePath)
    recoverAudio,
    required Future<Result<String?>> Function(
      TranscriptSummary transcript,
      AudioRecording audio,
    )
    fileAudio,
  }) async {
    final Result<List<TranscriptSummary>> found = await _repository.stale();
    if (found case FailureResult<List<TranscriptSummary>>(
      :final Failure failure,
    )) {
      _logger.warn(_tag, 'stale recordings could not be listed', error: failure);
      return FailureResult<int>(failure);
    }
    final List<TranscriptSummary> stale =
        (found as Success<List<TranscriptSummary>>).value;
    int settled = 0;
    int filed = 0;
    int unfiled = 0;
    for (final TranscriptSummary item in stale) {
      Duration? duration;
      if (item.ownerKind != TranscriptOwnerKind.capture &&
          item.attachmentId == null) {
        final AudioRecording? audio = await _recover(item, recoverAudio);
        if (audio != null) {
          duration = audio.duration;
          if (await _file(item, audio, fileAudio)) {
            filed++;
          } else {
            unfiled++;
          }
        }
      }
      final Result<TranscriptSummary> marked = await _repository
          .markInterrupted(item.id, duration: duration);
      if (marked is Success<TranscriptSummary>) {
        settled++;
      }
    }
    if (stale.isNotEmpty) {
      _logger.info(
        _tag,
        'launch recovery: ${stale.length} stale, $settled interrupted, '
        '$filed audio filed, $unfiled audio not filed',
      );
    }
    return Success<int>(settled);
  }

  Future<AudioRecording?> _recover(
    TranscriptSummary item,
    Future<Result<AudioRecording?>> Function(String storagePath) recoverAudio,
  ) async {
    final Result<AudioRecording?> recovered = await recoverAudio(
      item.audioPath,
    );
    return switch (recovered) {
      Success<AudioRecording?>(:final AudioRecording? value) => value,
      FailureResult<AudioRecording?>(:final Failure failure) => _skipped(
        failure,
      ),
    };
  }

  Future<bool> _file(
    TranscriptSummary item,
    AudioRecording audio,
    Future<Result<String?>> Function(TranscriptSummary, AudioRecording)
    fileAudio,
  ) async {
    final Result<String?> filed = await fileAudio(item, audio);
    if (filed case FailureResult<String?>(:final Failure failure)) {
      _logger.warn(_tag, 'a recovered recording was not filed', error: failure);
      return false;
    }
    final String? attachmentId = (filed as Success<String?>).value;
    if (attachmentId == null) {
      return false;
    }
    final Result<void> linked = await _repository.linkAttachment(
      item.id,
      attachmentId,
    );
    if (linked case FailureResult<void>(:final Failure failure)) {
      _logger.warn(_tag, 'a recovered recording was not linked', error: failure);
      return false;
    }
    return true;
  }

  AudioRecording? _skipped(Failure failure) {
    _logger.warn(_tag, 'a recording could not be recovered', error: failure);
    return null;
  }
}

const String _tag = 'speech';
