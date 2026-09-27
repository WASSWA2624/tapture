import 'value_candidate.dart';

/// A field whose independent sources disagree (task 015).
///
/// Nothing here picks a winner. A person does.
final class FieldConflict {
  /// Creates a conflict on [fieldKey].
  const FieldConflict(this.fieldKey, this.candidates);

  /// The field.
  final String fieldKey;

  /// Every candidate that is still in play.
  final List<ValueCandidate> candidates;
}
