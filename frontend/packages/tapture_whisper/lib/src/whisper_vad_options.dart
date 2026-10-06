/// How a whole buffer is cut into speech spans (`tw_vad_options`).
final class WhisperVadOptions {
  /// Describes the options; the defaults equal `tw_vad_options_init`.
  const WhisperVadOptions({
    this.threshold = 0.5,
    this.minSpeechMs = 250,
    this.minSilenceMs = 100,
    this.maxSpeechSeconds = maxFloat,
    this.speechPadMs = 30,
    this.overlapSeconds = 0.1,
  });

  /// The largest 32-bit float, the native "no limit" of [maxSpeechSeconds].
  static const double maxFloat = 3.4028234663852886e38;

  /// The largest value of each millisecond option (`TW_VAD_MAX_MS`); the
  /// native call refuses anything outside `[0, maxMs]` as an invalid argument.
  static const int maxMs = 60000;

  /// The speech probability a window needs, strictly between 0 and 1.
  final double threshold;

  /// The shortest span kept, in milliseconds, at most [maxMs].
  final int minSpeechMs;

  /// The shortest silence that ends a span, in milliseconds, at most [maxMs].
  final int minSilenceMs;

  /// The longest span before it is split, in seconds.
  final double maxSpeechSeconds;

  /// Padding added around each span, in milliseconds, at most [maxMs].
  final int speechPadMs;

  /// Overlap between split spans, in seconds.
  final double overlapSeconds;
}
