import 'package:tapture/core/widgets/fields/field_value.dart';

/// One proposed value for a field, with where it came from (task 015).
final class ValueCandidate {
  /// Creates a candidate from [source].
  const ValueCandidate(
    this.source,
    this.value,
    this.confidence,
    this.evidenceId,
  );

  /// Who proposed it.
  final ValueSource source;

  /// The proposed value.
  final Object? value;

  /// How sure the proposal was, from 0 to 1.
  final double confidence;

  /// The evidence the proposal was read from, when there is one.
  final String? evidenceId;
}
