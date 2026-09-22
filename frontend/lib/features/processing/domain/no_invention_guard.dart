/// Drops a value the evidence does not support, before it is applied.
final class NoInventionGuard {
  /// [value] is kept only when the evidence, pattern and options allow it.
  static GuardOutcome check({
    required String fieldKey,
    required String? value,
    required List<String> evidence,
    required bool evidenceRequired,
    String? pattern,
    List<String> options = const <String>[],
  }) {
    if (value == null || value.trim().isEmpty) {
      return (value: null, rejection: null);
    }
    if (evidenceRequired && evidence.isEmpty) {
      return (
        value: null,
        rejection: (
          fieldKey: fieldKey,
          reason: 'No evidence supports $fieldKey.',
        ),
      );
    }
    if (pattern != null && pattern.isNotEmpty) {
      try {
        if (!RegExp(pattern).hasMatch(value)) {
          return (
            value: null,
            rejection: (
              fieldKey: fieldKey,
              reason: '$fieldKey does not match its identifier pattern.',
            ),
          );
        }
      } on FormatException {
        return (
          value: null,
          rejection: (
            fieldKey: fieldKey,
            reason: '$fieldKey has a pattern that cannot be read.',
          ),
        );
      }
    }
    if (options.isNotEmpty &&
        !options.any(
          (String option) => option.toLowerCase() == value.toLowerCase(),
        )) {
      return (
        value: null,
        rejection: (
          fieldKey: fieldKey,
          reason: '$fieldKey is not one of the allowed options.',
        ),
      );
    }
    return (value: value, rejection: null);
  }
}

/// A dropped value and why the field stayed empty.
typedef GuardRejection = ({String fieldKey, String reason});

/// What [NoInventionGuard.check] kept or dropped.
typedef GuardOutcome = ({String? value, GuardRejection? rejection});
