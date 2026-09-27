/// One deleted record the purge may take (task 014 step 7, D13).
final class PurgeCandidate {
  /// Creates a candidate.
  const PurgeCandidate({
    required this.recordId,
    required this.projectId,
    required this.deletedAt,
    this.mergeNeeded = false,
  });

  /// Merge id of the deleted record.
  final String recordId;

  /// Project the record belongs to.
  final String projectId;

  /// When the record's tombstone was written.
  final DateTime deletedAt;

  /// Whether a merge still needs the record's tombstone: an unresolved
  /// conflict names it, or its project exchanges bundles and no bundle has
  /// left since the deletion. Such a record is never purged, window or not.
  final bool mergeNeeded;

  /// Returns a copy with the provided fields replaced.
  PurgeCandidate copyWith({
    String? recordId,
    String? projectId,
    DateTime? deletedAt,
    bool? mergeNeeded,
  }) {
    return PurgeCandidate(
      recordId: recordId ?? this.recordId,
      projectId: projectId ?? this.projectId,
      deletedAt: deletedAt ?? this.deletedAt,
      mergeNeeded: mergeNeeded ?? this.mergeNeeded,
    );
  }

  @override
  int get hashCode => Object.hash(recordId, projectId, deletedAt, mergeNeeded);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PurgeCandidate &&
            other.recordId == recordId &&
            other.projectId == projectId &&
            other.deletedAt == deletedAt &&
            other.mergeNeeded == mergeNeeded);
  }

  @override
  String toString() => 'PurgeCandidate($recordId)';
}
