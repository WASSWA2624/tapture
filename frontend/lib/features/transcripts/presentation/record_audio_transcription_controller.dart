import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/core/speech/live_transcription_event.dart';
import 'package:tapture/core/speech/live_transcription_service.dart';
import 'package:tapture/core/speech/speech_preferences.dart';
import 'package:tapture/core/speech/speech_readiness_notifier.dart';
import 'package:tapture/core/speech/transcript_sink.dart';

import '../domain/transcript_repository.dart';
import '../domain/transcript_start.dart';
import '../domain/transcript_summary.dart';
import '../transcripts.dart' show transcriptRepositoryProvider;

/// **Transcribe on this device** on a record's page (spec §24, §30.4.6): each
/// audio clip filed on the record with no transcript gets one, heard from
/// the stored take on this device.
///
/// Each clip begins a capture transcript linked to it, then the whole take
/// is transcribed from its start through the speech service, which always
/// finishes the transcript: complete when the take was covered, otherwise
/// interrupted with what was heard kept. The state is whether a run is
/// going. Leaving the page does not stop it.
final class RecordAudioTranscriptionController extends Notifier<bool> {
  /// A controller for the audio of record [recordId].
  RecordAudioTranscriptionController(this.recordId);

  /// The record whose audio is transcribed.
  final String recordId;

  @override
  bool build() => false;

  /// Transcribes every clip of the record that has no transcript yet, one
  /// after another, and reports the first failure. A second request while
  /// one runs is refused.
  Future<Result<void>> transcribe() async {
    if (state) {
      return const FailureResult<void>(ValidationFailure());
    }
    final TranscriptRepository repository = ref.read(
      transcriptRepositoryProvider,
    );
    final LiveTranscriptionService service = ref.read(
      liveTranscriptionServiceProvider,
    );
    final String languageTag = ref.read(speechLanguageProvider);
    final String modelId =
        ref.read(speechReadinessProvider).selection?.model.id ?? '';
    final Logger logger = Logger.current;
    // The run is the operator's request; it outlives the page.
    final KeepAliveLink keepAlive = ref.keepAlive();
    state = true;
    try {
      final List<TranscriptStart> clips = await repository
          .watchUntranscribedAudio(recordId)
          .first;
      logger.info(_tag, 'transcribing ${clips.length} clips on this device');
      Failure? first;
      for (final TranscriptStart clip in clips) {
        final Failure? failed = await _transcribeClip(repository, service, (
          projectId: clip.projectId,
          ownerKind: clip.ownerKind,
          ownerId: clip.ownerId,
          attachmentId: clip.attachmentId,
          audioPath: clip.audioPath,
          title: clip.title,
          languageTag: languageTag,
          modelId: modelId,
          startedAt: clip.startedAt,
        ));
        if (failed != null) {
          logger.warn(_tag, 'clip not transcribed (${failed.runtimeType})');
          first ??= failed;
        }
      }
      final Failure? failure = first;
      return failure == null
          ? const Success<void>(null)
          : FailureResult<void>(failure);
    } finally {
      if (ref.mounted) {
        state = false;
      }
      keepAlive.close();
    }
  }

  /// Begins the transcript of [start] and transcribes its take from the
  /// first sample; the failure, if any.
  Future<Failure?> _transcribeClip(
    TranscriptRepository repository,
    LiveTranscriptionService service,
    TranscriptStart start,
  ) async {
    final Result<TranscriptSummary> begun = await repository.begin(start);
    final String transcriptId;
    switch (begun) {
      case FailureResult<TranscriptSummary>(:final Failure failure):
        return failure;
      case Success<TranscriptSummary>(:final TranscriptSummary value):
        transcriptId = value.id;
    }
    final Result<TranscriptSink> sink = await repository.sinkFor(transcriptId);
    final TranscriptSink writer;
    switch (sink) {
      case FailureResult<TranscriptSink>(:final Failure failure):
        // Nothing was heard yet: the empty row is not left behind.
        await repository.discard(transcriptId);
        return failure;
      case Success<TranscriptSink>(:final TranscriptSink value):
        writer = value;
    }
    Failure? failed;
    await for (final LiveTranscriptionEvent event
        in service.transcribeRemaining(
          start.audioPath,
          gaps: const <(int, int)>[],
          fromSample: 0,
          nextSegmentId: 1,
          languageTag: start.languageTag,
          sink: writer,
        )) {
      if (event case TranscriptionFailed(:final Failure failure)) {
        failed = failure;
      }
    }
    return failed;
  }
}

const String _tag = 'transcripts';
