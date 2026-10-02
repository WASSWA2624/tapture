import 'package:tapture/core/widgets/record_status.dart';

/// The status groups an export summary counts, shared by the app's export
/// summary and the project summary report so the two always agree
/// (task 018 step 11).
enum ExportStatusBucket {
  /// Waiting to be processed, being processed, or failed and waiting again.
  unprocessed,

  /// Waiting for a person to review.
  needsReview,

  /// Approved.
  approved;

  /// Statuses counted as [unprocessed].
  static const List<RecordStatus> unprocessedStatuses = <RecordStatus>[
    RecordStatus.draft,
    RecordStatus.captured,
    RecordStatus.queued,
    RecordStatus.processing,
    RecordStatus.failed,
  ];

  /// The group of the stored status [stored], or null when the summary
  /// counts it in no group (extracted, archived, deleted or unknown).
  static ExportStatusBucket? of(String stored) {
    final RecordStatus? status = RecordStatus.fromStored(stored);
    if (status == null) {
      return null;
    }
    if (unprocessedStatuses.contains(status)) {
      return unprocessed;
    }
    return switch (status) {
      RecordStatus.needsReview => needsReview,
      RecordStatus.approved => approved,
      _ => null,
    };
  }
}
