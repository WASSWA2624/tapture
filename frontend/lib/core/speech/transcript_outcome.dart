/// How a transcript ended, written once by `TranscriptSink.finish`.
final class TranscriptOutcome {
  /// Reports a transcript that is [complete] or interrupted, over [captured]
  /// audio, covered up to [coveredToSample], in [languageTag] by [modelId].
  const TranscriptOutcome({
    required this.complete,
    required this.captured,
    required this.coveredToSample,
    required this.languageTag,
    this.modelId,
  });

  /// Whether every captured sample was transcribed or recorded as a gap.
  final bool complete;

  /// How much audio the recording holds.
  final Duration captured;

  /// The sample up to which the transcript accounts for the audio.
  final int coveredToSample;

  /// The BCP 47 tag of the language the session used.
  final String languageTag;

  /// The catalogue id of the model that decoded it, or null when no model
  /// ever loaded.
  final String? modelId;

  @override
  bool operator ==(Object other) =>
      other is TranscriptOutcome &&
      other.complete == complete &&
      other.captured == captured &&
      other.coveredToSample == coveredToSample &&
      other.languageTag == languageTag &&
      other.modelId == modelId;

  @override
  int get hashCode =>
      Object.hash(complete, captured, coveredToSample, languageTag, modelId);
}
