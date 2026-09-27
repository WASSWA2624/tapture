import 'field_variance.dart';
import 'identity_hash.dart';

/// Compares as-recorded with as-found (task 015).
///
/// A formatting difference alone is a match. Computation proposes the
/// status; it does not resolve anything.
abstract final class VarianceComputation {
  /// One row per [fieldKeys], in that order.
  static List<FieldVariance> compare({
    required Map<String, Object?> recorded,
    required Map<String, Object?> found,
    required List<String> fieldKeys,
  }) {
    return <FieldVariance>[
      for (final String key in fieldKeys)
        FieldVariance(
          key,
          recorded[key],
          found[key],
          _status(recorded[key], found[key]),
        ),
    ];
  }
}

VarianceStatus _status(Object? recorded, Object? found) {
  final String left = normaliseIdentity('${recorded ?? ''}');
  final String right = normaliseIdentity('${found ?? ''}');
  if (left.isEmpty && right.isEmpty) {
    return VarianceStatus.match;
  }
  if (left.isNotEmpty && right.isEmpty) {
    return VarianceStatus.missing;
  }
  if (left == right) {
    return VarianceStatus.match;
  }
  return VarianceStatus.changed;
}
