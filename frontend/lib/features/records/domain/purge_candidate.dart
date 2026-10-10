/// One deleted record the purge may take (task 014 step 7, D13).
final class PurgeCandidate {
  /// Creates a candidate.
  const PurgeCandidate({
    required this.recordId,
    required this.projectId,
    required this.deletedAt,
    this.deletionId,
    this.mergeNeeded = false,
  });

  /// Merge id of the deleted record.
  final String recordId;

  /// Project the record belongs to.
  final String projectId;

  /// When the record's tombstone was written.
  final DateTime deletedAt;

  /// The tombstone this candidate authorizes; null only for legacy fixtures.
  final String? deletionId;

  /// Whether a merge still needs the record's tombstone: an unresolved
  /// conflict names it, or its project exchanges bundles and no bundle has
  /// left since the deletion. Automatic retention never purges such a record.
  final bool mergeNeeded;

  /// Returns a copy with the provided fields replaced.
  PurgeCandidate copyWith({
    String? recordId,
    String? projectId,
    DateTime? deletedAt,
    String? deletionId,
    bool? mergeNeeded,
  }) {
    return PurgeCandidate(
      recordId: recordId ?? this.recordId,
      projectId: projectId ?? this.projectId,
      deletedAt: deletedAt ?? this.deletedAt,
      deletionId: deletionId ?? this.deletionId,
      mergeNeeded: mergeNeeded ?? this.mergeNeeded,
    );
  }

  @override
  int get hashCode =>
      Object.hash(recordId, projectId, deletedAt, deletionId, mergeNeeded);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PurgeCandidate &&
            other.recordId == recordId &&
            other.projectId == projectId &&
            other.deletedAt == deletedAt &&
            other.deletionId == deletionId &&
            other.mergeNeeded == mergeNeeded);
  }

  @override
  String toString() => 'PurgeCandidate($recordId)';
}
