/// Bands a confidence score with the project's thresholds.
///
/// One function, so every screen that shows a band reads the same cut.
final class Confidence {
  /// [high] and [medium] come from the settings store.
  static ConfidenceBand band({
    required double score,
    required double high,
    required double medium,
  }) {
    if (score >= high) {
      return ConfidenceBand.high;
    }
    if (score >= medium) {
      return ConfidenceBand.medium;
    }
    return ConfidenceBand.reviewRequired;
  }
}

/// High, medium, or review required.
enum ConfidenceBand {
  /// At or above the project's high threshold.
  high,

  /// At or above the project's medium threshold.
  medium,

  /// Below medium. A person must look.
  reviewRequired,
}
