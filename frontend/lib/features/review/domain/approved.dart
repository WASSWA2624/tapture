part of 'approval_outcome.dart';

/// The record was approved. [nextRecordId] is the next unreviewed record.
final class Approved extends ApprovalOutcome {
  /// Creates a successful approval.
  Approved(this.nextRecordId);

  /// The next record in the filter, or null at the end of the queue.
  final String? nextRecordId;
}
