import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/core/speech/live_transcription_event.dart';
import 'package:tapture/core/speech/live_transcription_service.dart';
import 'package:tapture/core/speech/speech_preferences.dart';
import 'package:tapture/core/speech/transcript_sink.dart';
import 'package:tapture/features/settings/settings.dart'
    show currentOperatorProvider;

import '../domain/transcript.dart';
import '../domain/transcript_gap.dart';
import '../domain/transcript_repository.dart';
import '../domain/transcript_status.dart';
import '../domain/transcript_summary.dart';
import '../transcripts.dart' show transcriptRepositoryProvider;
import 'transcript_detail_status.dart';

/// Runs one transcript's page (spec §30.4.6): the operator's edit, saved
/// beside the raw segments and audited; going back to the original;
/// renaming; and **Finish the transcript**, which transcribes on the device
/// what the recording still lacks.
///
/// Raw segments are never rewritten: an edit is stored beside them, and a
/// finish only appends segments for the gaps and the tail, numbered on
/// from the last one stored. A live transcript is still being written, so
/// it is neither edited nor finished.
final class TranscriptDetailController
    extends Notifier<TranscriptDetailStatus> {
  /// A controller for transcript [transcriptId].
  TranscriptDetailController(this.transcriptId);

  /// The transcript this page shows.
  final String transcriptId;

  @override
  TranscriptDetailStatus build() => const TranscriptDetailStatus();

  /// Keeps [text] as the unsaved edit.
  void edit(String text) {
    if (text != state.draft) {
      state = state.copyWith(draft: text);
    }
  }

  /// Forgets the unsaved edit, as when the operator leaves without saving.
  void dropDraft() {
    state = state.copyWith(clearDraft: true);
  }

  /// Saves [text] beside the raw segments, audited. Text identical to the
  /// raw text clears the edit.
  Future<Result<Transcript>> save(String text) {
    return _write(
      (TranscriptRepository repository, String? operator) =>
          repository.saveEdit(transcriptId, text, operator: operator),
    );
  }

  /// Removes the edit, audited, so the transcript reads as it was heard.
  Future<Result<Transcript>> revert() {
    return _write(
      (TranscriptRepository repository, String? operator) =>
          repository.clearEdit(transcriptId, operator: operator),
    );
  }

  /// Renames the transcript to [title], trimmed, audited. An empty title
  /// leaves it untitled.
  Future<Result<TranscriptSummary>> rename(String title) async {
    if (state.saving) {
      return const FailureResult<TranscriptSummary>(ValidationFailure());
    }
    final TranscriptRepository repository = ref.read(
      transcriptRepositoryProvider,
    );
    final String? operator = _operator();
    state = state.copyWith(saving: true);
    final Result<TranscriptSummary> renamed = await repository.rename(
      transcriptId,
      title.trim(),
      operator: operator,
    );
    if (ref.mounted) {
      state = state.copyWith(saving: false);
    }
    return renamed;
  }

  /// Transcribes what the recording still lacks, on this device: each gap,
  /// then the audio past the covered point. The transcript is reopened for
  /// the run and is complete afterwards when everything was covered, or
  /// keeps the status it had. Leaving the page does not stop the run.
  Future<Result<void>> finish() async {
    if (state.finishing) {
      return const FailureResult<void>(ValidationFailure());
    }
    final TranscriptRepository repository = ref.read(
      transcriptRepositoryProvider,
    );
    final LiveTranscriptionService service = ref.read(
      liveTranscriptionServiceProvider,
    );
    final String language = ref.read(speechLanguageProvider);
    final Logger logger = Logger.current;
    // The run outlives the page: it is the operator's request, and stopping
    // it half way would only leave the rest for another tap.
    final KeepAliveLink keepAlive = ref.keepAlive();
    state = state.copyWith(finishing: true);
    try {
      final Result<void> finished = await _finish(
        repository,
        service,
        language,
        logger,
      );
      if (finished case FailureResult<void>(:final Failure failure)) {
        logger.warn(_tag, 'transcript not finished (${failure.runtimeType})');
      }
      return finished;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(finishing: false);
      }
      keepAlive.close();
    }
  }

  Future<Result<void>> _finish(
    TranscriptRepository repository,
    LiveTranscriptionService service,
    String fallbackLanguage,
    Logger logger,
  ) async {
    final Result<Transcript?> read = await repository.read(transcriptId);
    final Transcript transcript;
    switch (read) {
      case FailureResult<Transcript?>(:final Failure failure):
        return FailureResult<void>(failure);
      case Success<Transcript?>(:final Transcript? value):
        if (value == null) {
          return const FailureResult<void>(ValidationFailure());
        }
        transcript = value;
    }
    final TranscriptSummary summary = transcript.summary;
    if (summary.status == TranscriptStatus.live) {
      return FailureResult<void>(
        ValidationFailure(
          localizedMessage: Copy.messages.transcriptStillRecording,
        ),
      );
    }
    if (!summary.remaining) {
      return const Success<void>(null);
    }
    final Result<void> reopened = await repository.reopenForRemaining(
      transcriptId,
    );
    if (reopened case FailureResult<void>(:final Failure failure)) {
      return FailureResult<void>(failure);
    }
    final Result<TranscriptSink> sink = await repository.sinkFor(transcriptId);
    final TranscriptSink writer;
    switch (sink) {
      case FailureResult<TranscriptSink>(:final Failure failure):
        return FailureResult<void>(failure);
      case Success<TranscriptSink>(:final TranscriptSink value):
        writer = value;
    }
    logger.info(
      _tag,
      'finishing a transcript (${summary.gaps.length} gaps, '
      '${summary.ownerKind.name})',
    );
    Failure? failed;
    // The service always finishes the sink, which completes the transcript
    // or restores the status it had.
    await for (final LiveTranscriptionEvent event
        in service.transcribeRemaining(
          summary.audioPath,
          gaps: <(int, int)>[
            for (final TranscriptGap gap in summary.gaps)
              (_samplesOf(gap.start), _samplesOf(gap.end)),
          ],
          fromSample: _samplesOf(Duration(milliseconds: summary.coveredMs)),
          nextSegmentId: transcript.nextSegmentId,
          languageTag: summary.languageTag.isEmpty
              ? fallbackLanguage
              : summary.languageTag,
          sink: writer,
        )) {
      if (event case TranscriptionFailed(:final Failure failure)) {
        failed = failure;
      }
    }
    final Failure? failure = failed;
    return failure == null
        ? const Success<void>(null)
        : FailureResult<void>(failure);
  }

  /// Runs one audited write of the edit, refusing a second while one is in
  /// flight, and drops the draft once it lands.
  Future<Result<Transcript>> _write(
    Future<Result<Transcript>> Function(
      TranscriptRepository repository,
      String? operator,
    )
    write,
  ) async {
    if (state.saving) {
      return const FailureResult<Transcript>(ValidationFailure());
    }
    final TranscriptRepository repository = ref.read(
      transcriptRepositoryProvider,
    );
    final String? operator = _operator();
    state = state.copyWith(saving: true);
    final Result<Transcript> written = await write(repository, operator);
    if (ref.mounted) {
      state = state.copyWith(
        saving: false,
        clearDraft: written is Success<Transcript>,
      );
    }
    return written;
  }

  /// The operator the audit names, when the profile has loaded.
  String? _operator() {
    final String? name = ref.read(currentOperatorProvider)?.name;
    return name == null || name.isEmpty ? null : name;
  }

  /// [at] on the 16 kHz timeline, in samples.
  static int _samplesOf(Duration at) =>
      at.inMicroseconds *
      AppConstants.audio.sampleRate ~/
      Duration.microsecondsPerSecond;
}

const String _tag = 'transcripts';
