import 'record_summary.dart';

/// One record in the recycle bin (task 014 step 7, D12).
///
/// Its files and rows are all still on the device until the purge takes it
/// once the retention window has passed, so a restore brings it back whole.
final class DeletedRecord {
  /// Creates a recycle bin row.
  const DeletedRecord({
    required this.summary,
    required this.deletedAt,
    this.deletionId,
    this.projectName = '',
    this.reason = '',
  });

  /// The record as its list row showed it.
  final RecordSummary summary;

  /// Name of the project the record belongs to.
  final String projectName;

  /// When the record was deleted.
  final DateTime deletedAt;

  /// Tombstone identity retained across the selection/confirmation boundary.
  final String? deletionId;

  /// Why it was deleted, as the tombstone recorded it.
  final String reason;

  /// Merge id of the record.
  String get id => summary.id;

  /// Whole days left before the purge may take the record, never below 0.
  ///
  /// [retentionDays] is the operator's recycle bin window; a record deleted
  /// exactly that many whole days before [now] has 0 days left.
  int daysLeft({required DateTime now, required int retentionDays}) {
    final int elapsed = now.difference(deletedAt).inDays;
    final int left = retentionDays - (elapsed < 0 ? 0 : elapsed);
    return left < 0 ? 0 : left;
  }

  /// Returns a copy with the provided fields replaced.
  DeletedRecord copyWith({
    RecordSummary? summary,
    String? projectName,
    DateTime? deletedAt,
    String? deletionId,
    String? reason,
  }) {
    return DeletedRecord(
      summary: summary ?? this.summary,
      projectName: projectName ?? this.projectName,
      deletedAt: deletedAt ?? this.deletedAt,
      deletionId: deletionId ?? this.deletionId,
      reason: reason ?? this.reason,
    );
  }

  @override
  int get hashCode =>
      Object.hash(summary, projectName, deletedAt, deletionId, reason);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DeletedRecord &&
            other.summary == summary &&
            other.projectName == projectName &&
            other.deletedAt == deletedAt &&
            other.deletionId == deletionId &&
            other.reason == reason);
  }

  @override
  String toString() => 'DeletedRecord($id)';
}
