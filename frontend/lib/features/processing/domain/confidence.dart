import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/widgets/record_status.dart';

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
///
/// The band carries its own look, so every screen that shows one draws the
/// same tone and words (task 013 step 10).
enum ConfidenceBand {
  /// At or above the project's high threshold.
  high,

  /// At or above the project's medium threshold.
  medium,

  /// Below medium. A person must look.
  reviewRequired;

  /// The band a stored `confidence_band` names, folding case and
  /// punctuation (`reviewRequired`, `review_required` and the older `low`
  /// alike), or null when it names none.
  static ConfidenceBand? fromStored(String? stored) {
    final String folded = (stored ?? '').toLowerCase().replaceAll(
      _nonLetter,
      '',
    );
    return switch (folded) {
      'high' => ConfidenceBand.high,
      'medium' => ConfidenceBand.medium,
      'reviewrequired' || 'low' => ConfidenceBand.reviewRequired,
      _ => null,
    };
  }

  /// The status tone the shared pill draws this band in.
  RecordStatus get tone {
    return switch (this) {
      ConfidenceBand.high => RecordStatus.approved,
      ConfidenceBand.medium => RecordStatus.extracted,
      ConfidenceBand.reviewRequired => RecordStatus.needsReview,
    };
  }

  /// This band in the operator's words.
  String get label {
    return switch (this) {
      ConfidenceBand.high => DomainCopy.recordBandHigh,
      ConfidenceBand.medium => DomainCopy.recordBandMedium,
      ConfidenceBand.reviewRequired => DomainCopy.recordBandLow,
    };
  }
}

final RegExp _nonLetter = RegExp('[^a-z]');
