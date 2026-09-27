/// Restores the snapshot taken before a merge, until it is purged.
final class MergeUndo {
  /// Creates an undo.
  const MergeUndo();

  /// Whether undo is still offered for [mergeId].
  bool isAvailable(String mergeId, {required bool purged}) {
    return mergeId.isNotEmpty && !purged;
  }

  /// The project as it was, including rows and files the merge removed.
  Map<String, String> undo({
    required Map<String, String> snapshot,
    required bool purged,
  }) {
    if (purged) {
      throw StateError('The snapshot has been purged.');
    }
    return <String, String>{...snapshot};
  }
}
