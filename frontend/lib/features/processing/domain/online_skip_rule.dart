import 'confidence.dart';

/// Skips the online stage when local work already fills the record.
final class OnlineSkipRule {
  /// A reason to skip, or null when an online call is still needed.
  ///
  /// Every required field must be filled and banded high.
  static String? reason(List<SkipField> fields) {
    final List<SkipField> required = <SkipField>[
      for (final SkipField field in fields)
        if (field.requiredField) field,
    ];
    if (required.isEmpty) {
      return null;
    }
    for (final SkipField field in required) {
      if (field.value == null || field.value!.trim().isEmpty) {
        return null;
      }
      if (field.band != ConfidenceBand.high) {
        return null;
      }
    }
    return 'Local extraction and a reference match already fill every required field.';
  }
}

/// A field the skip rule looks at.
typedef SkipField = ({bool requiredField, String? value, ConfidenceBand? band});
