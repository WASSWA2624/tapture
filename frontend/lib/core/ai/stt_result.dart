/// One update from [SttService.listen]: the words heard so far, or the last
/// of them.
final class SttResult {
  /// Creates a result. [text] is exactly what the recogniser returned.
  const SttResult({
    required this.text,
    required this.isFinal,
    required this.languageTag,
    this.confidence,
  });

  /// Words heard in this listen so far. Empty while the microphone opens.
  final String text;

  /// Whether this is the last update of the listen.
  final bool isFinal;

  /// The language actually used, not only the one requested.
  final String languageTag;

  /// The recogniser's confidence from 0 to 1, when it reports one.
  final double? confidence;
}
