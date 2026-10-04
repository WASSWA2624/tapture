/// A timed fragment of decoded text, usually a word or part of one.
///
/// Called a piece rather than a token so it never reads as a secret in logs.
final class SpeechPiece {
  /// Describes [text] heard from [startSample] to [endSample].
  const SpeechPiece({
    required this.startSample,
    required this.endSample,
    required this.text,
    required this.probability,
  });

  /// First sample on the session timeline, at 16 kHz.
  final int startSample;

  /// Sample after the last one, on the session timeline.
  final int endSample;

  /// Valid UTF-8 text, often with a leading space.
  final String text;

  /// The model's probability for this piece, from 0 to 1.
  final double probability;

  @override
  bool operator ==(Object other) =>
      other is SpeechPiece &&
      other.startSample == startSample &&
      other.endSample == endSample &&
      other.text == text &&
      other.probability == probability;

  @override
  int get hashCode => Object.hash(startSample, endSample, text, probability);
}
