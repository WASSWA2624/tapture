/// One stretch of speech the VAD found (`tw_span`).
final class WhisperSpeechSpan {
  /// Describes one span.
  const WhisperSpeechSpan({required this.startMs, required this.endMs});

  /// Where speech starts, in milliseconds from the start of the buffer.
  final int startMs;

  /// Where speech ends, in milliseconds from the start of the buffer.
  final int endMs;
}
