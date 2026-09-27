import 'package:tapture/core/validation/validation_issue.dart';
import 'package:tapture/features/records/records.dart' show RecordFilter;

/// The reads and the status move approve-and-next needs (task 016).
abstract interface class ApprovalSteps {
  /// Validation issues for [recordId], including warnings.
  Future<List<ValidationIssue>> issues(String recordId);

  /// Whether [recordId] is still in an unresolved duplicate pair.
  Future<bool> unresolvedDuplicate(String recordId);

  /// Field keys that still have a source conflict.
  Future<List<String>> conflictFields(String recordId);

  /// The next unreviewed record in [filter] after [recordId].
  Future<String?> nextUnreviewed(RecordFilter filter, String recordId);

  /// Moves [recordId] to approved. Called only on a clean decision.
  Future<void> markApproved(String recordId);
}
