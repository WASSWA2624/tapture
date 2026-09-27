import 'field_conflict.dart';
import 'identity_hash.dart';
import 'value_candidate.dart';

/// Raises a conflict only when normalised values genuinely differ (task 015).
///
/// `ABB-1234` and `abb 1234` are one value. A single candidate, or several
/// that fold to the same text, is not a conflict.
abstract final class ConflictDetection {
  /// Conflicts among [byField], field key to its candidates.
  static List<FieldConflict> find(Map<String, List<ValueCandidate>> byField) {
    final List<FieldConflict> conflicts = <FieldConflict>[];
    for (final MapEntry<String, List<ValueCandidate>> entry
        in byField.entries) {
      final List<ValueCandidate> candidates = entry.value;
      if (candidates.length < 2) {
        continue;
      }
      final Set<String> folded = <String>{
        for (final ValueCandidate candidate in candidates)
          normaliseIdentity('${candidate.value ?? ''}'),
      };
      if (folded.length > 1) {
        conflicts.add(
          FieldConflict(entry.key, List<ValueCandidate>.of(candidates)),
        );
      }
    }
    return conflicts;
  }
}
