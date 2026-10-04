part of 'live_transcription_event.dart';

/// An utterance is finished; it follows its segments, and comes even when
/// it produced none, so a draft of it can be cleared.
final class UtteranceFinalized extends LiveTranscriptionEvent {
  /// Utterance [utteranceId] over samples [fromSample] to [toSample]
  /// produced [segmentCount] segments; [skipped] when it could not be
  /// transcribed and is a gap.
  const UtteranceFinalized({
    required this.utteranceId,
    required this.fromSample,
    required this.toSample,
    required this.segmentCount,
    required this.durable,
    this.skipped = false,
  });

  /// The utterance's place in the session.
  final int utteranceId;

  /// Its first sample on the session timeline.
  final int fromSample;

  /// The sample after its last one.
  final int toSample;

  /// Segments it produced.
  final int segmentCount;

  /// False only when the sink failed to store it.
  final bool durable;

  /// Whether it was left untranscribed and recorded as a gap.
  final bool skipped;
}
