/// Reference rows merge by key. A differing key is a conflict.
final class MergeReference {
  /// New, identical, or a conflict. Differing attributes are never overwritten.
  static ReferenceOutcome resolve({
    required bool localExists,
    required Map<String, String> local,
    required Map<String, String> incoming,
  }) {
    if (!localExists) {
      return ReferenceOutcome.insert;
    }
    if (local.length == incoming.length) {
      var same = true;
      for (final MapEntry<String, String> entry in local.entries) {
        if (incoming[entry.key] != entry.value) {
          same = false;
        }
      }
      if (same) {
        return ReferenceOutcome.identical;
      }
    }
    return ReferenceOutcome.conflict;
  }
}

/// How one reference key combines.
enum ReferenceOutcome { insert, identical, conflict }
