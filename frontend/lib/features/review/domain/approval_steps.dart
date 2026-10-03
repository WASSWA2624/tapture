import 'package:tapture/core/validation/validation_issue.dart';
import 'package:tapture/features/records/domain/domain.dart' show RecordFilter;

/// The reads and the status move approve-and-next needs, so the decision
/// stays free of storage.
abstract interface class ApprovalSteps {
  /// Validation issues for [recordId], including warnings.
  Future<List<ValidationIssue>> issues(String recordId);

  /// Whether [recordId] is still in an unresolved duplicate pair.
  Future<bool> unresolvedDuplicate(String recordId);

  /// Each field of [recordId] still in an unresolved conflict, by key, with
  /// the label a block names it by.
  Future<Map<String, String>> conflictFields(String recordId);

  /// The next unreviewed record in [filter] after [recordId].
  Future<String?> nextUnreviewed(RecordFilter filter, String recordId);

  /// Moves [recordId] to approved. Called only on a clean decision.
  Future<void> markApproved(String recordId);
}
