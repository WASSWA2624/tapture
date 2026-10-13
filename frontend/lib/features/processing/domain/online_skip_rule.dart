import 'confidence.dart';

/// Skips the online stage when local work already fills the record.
final class OnlineSkipRule {
  /// A reason to skip, or null when an online call is still needed.
  ///
  /// Every requested field must be filled and banded high, including optional
  /// fields. Requiredness governs review, never whether extraction is attempted.
  static String? reason(List<SkipField> fields) {
    if (fields.isEmpty) {
      return 'No eligible fields need online extraction.';
    }
    for (final SkipField field in fields) {
      if (field.value == null || field.value!.trim().isEmpty) {
        return null;
      }
      if (field.band != ConfidenceBand.high) {
        return null;
      }
    }
    return 'Local extraction already fills every requested field.';
  }
}

/// A field the skip rule looks at.
typedef SkipField = ({bool requiredField, String? value, ConfidenceBand? band});
