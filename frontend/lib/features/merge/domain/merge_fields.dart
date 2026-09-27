/// Field-by-field comparison of a concurrent record (task 019).
final class MergeFields {
  /// One-sided changes apply, identical values raise nothing, differences
  /// escalate.
  static FieldMerge compare({
    required String? mine,
    required String? theirs,
    required bool mineChanged,
    required bool theirsChanged,
  }) {
    if (mine == theirs) {
      return FieldMerge.identical;
    }
    if (mineChanged && !theirsChanged) {
      return FieldMerge.applyMine;
    }
    if (theirsChanged && !mineChanged) {
      return FieldMerge.applyTheirs;
    }
    return FieldMerge.escalate;
  }
}

/// How two field values combine.
enum FieldMerge { identical, applyMine, applyTheirs, escalate }
