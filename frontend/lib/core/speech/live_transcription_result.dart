import 'finished_utterance.dart';
import 'stop_reason.dart';
import 'transcript_segment.dart';

/// How a live transcription session ended once its transcript was
/// finished or skipped (spec §30.4.5).
final class LiveTranscriptionResult {
  /// A session that produced [segments] in [languageTag] with [modelId]
  /// over [captured] of audio, accounting for it up to [coveredToSample],
  /// [transcriptComplete] when every sample was, with [unsaved] utterances
  /// its sink never stored, stopped for [stopReason].
  const LiveTranscriptionResult({
    required this.segments,
    required this.languageTag,
    required this.modelId,
    required this.captured,
    required this.transcriptComplete,
    required this.coveredToSample,
    required this.unsaved,
    required this.stopReason,
  });

  /// Every segment finalized, in order, stored or not.
  final List<TranscriptSegment> segments;

  /// The BCP 47 tag the session transcribed in.
  final String languageTag;

  /// The catalogue id of the model that decoded it, or null when none
  /// loaded.
  final String? modelId;

  /// How much audio was captured.
  final Duration captured;

  /// Whether every captured sample was transcribed or recorded as a gap.
  final bool transcriptComplete;

  /// The sample up to which the transcript accounts for the audio.
  final int coveredToSample;

  /// Utterances the sink failed to store, oldest first.
  final List<FinishedUtterance> unsaved;

  /// Why capture stopped.
  final StopReason stopReason;
}
