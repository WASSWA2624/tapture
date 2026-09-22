/// Verbatim speech transcript stored beside a caption row. Refinement
/// never overwrites these fields (FE-SEC-08).
final class TranscriptStore {
  /// Creates a store entry.
  const TranscriptStore({
    required this.text,
    required this.languageTag,
    this.confidence,
  });

  /// Exact words as recognised.
  final String text;

  /// Language actually used, not the one requested.
  final String languageTag;

  /// Optional confidence 0–1.
  final double? confidence;

  /// JSON for caption-row metadata.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'text': text,
      'languageTag': languageTag,
      'confidence': confidence,
    };
  }

  /// Restores from [toJson].
  static TranscriptStore fromJson(Map<String, Object?> json) {
    return TranscriptStore(
      text: json['text'] as String? ?? '',
      languageTag: json['languageTag'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  /// Refinement writes a separate column — this row stays unchanged.
  TranscriptStore get unchangedByRefinement => this;
}
