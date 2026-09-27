/// What one purge run did, as counts only (D13).
///
/// Counts are all that is logged: a record's values never reach a log
/// (FE-CODE-08).
final class PurgeReport {
  /// Creates a report.
  const PurgeReport({
    this.purged = 0,
    this.skippedRecent = 0,
    this.skippedMergeNeeded = 0,
    this.filesRemoved = 0,
    this.failed = 0,
  });

  /// A run that found nothing in the recycle bin.
  static const PurgeReport none = PurgeReport();

  /// Records removed for good.
  final int purged;

  /// Records left alone because their window has not passed.
  final int skippedRecent;

  /// Records left alone because a merge still needs their tombstone.
  final int skippedMergeNeeded;

  /// Photo files and cached thumbnails removed with the purged records.
  final int filesRemoved;

  /// Records the purge tried and could not remove; they stay for next time.
  final int failed;

  /// How many records the run looked at.
  int get considered => purged + skippedRecent + skippedMergeNeeded + failed;

  /// One line for the launch log: counts and nothing else.
  String get summary =>
      'purged $purged, recent $skippedRecent, '
      'merge needed $skippedMergeNeeded, files $filesRemoved, failed $failed';

  /// Returns a copy with the provided fields replaced.
  PurgeReport copyWith({
    int? purged,
    int? skippedRecent,
    int? skippedMergeNeeded,
    int? filesRemoved,
    int? failed,
  }) {
    return PurgeReport(
      purged: purged ?? this.purged,
      skippedRecent: skippedRecent ?? this.skippedRecent,
      skippedMergeNeeded: skippedMergeNeeded ?? this.skippedMergeNeeded,
      filesRemoved: filesRemoved ?? this.filesRemoved,
      failed: failed ?? this.failed,
    );
  }

  @override
  int get hashCode => Object.hash(
    purged,
    skippedRecent,
    skippedMergeNeeded,
    filesRemoved,
    failed,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PurgeReport &&
            other.purged == purged &&
            other.skippedRecent == skippedRecent &&
            other.skippedMergeNeeded == skippedMergeNeeded &&
            other.filesRemoved == filesRemoved &&
            other.failed == failed);
  }

  @override
  String toString() => 'PurgeReport($summary)';
}
