import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/validation/severity.dart';
import 'package:tapture/core/validation/validation_issue.dart';
import 'package:tapture/features/records/domain/domain.dart' show RecordFilter;

import 'approval_outcome.dart';
import 'approval_steps.dart';

export 'approval_steps.dart';

/// Decides whether a record may be approved, then which record is next
/// (task 016).
///
/// Validation errors, an unresolved duplicate and an unresolved conflict
/// all block, each naming the field and what must be fixed. Nothing here
/// approves a value that a person did not accept.
final class ApproveRecord {
  /// The block conditions and the clean path, with no I/O.
  ///
  /// [conflictFields] maps each field still in an unresolved conflict to the
  /// label the block names it by.
  static ApprovalOutcome assess({
    required List<ValidationIssue> issues,
    required bool unresolvedDuplicate,
    required Map<String, String> conflictFields,
    required String? nextRecordId,
  }) {
    final List<ValidationIssue> reasons = <ValidationIssue>[
      for (final ValidationIssue issue in issues)
        if (issue.blocks) issue,
      if (unresolvedDuplicate)
        ValidationIssue(
          null,
          Severity.error,
          DomainCopy.reviewBlockedDuplicate,
        ),
      for (final MapEntry<String, String> field in conflictFields.entries)
        ValidationIssue(
          field.key,
          Severity.error,
          DomainCopy.conflictBlocksApproval(field.value),
        ),
    ];
    if (reasons.isNotEmpty) {
      return Blocked(reasons);
    }
    return Approved(nextRecordId);
  }

  /// Approves [recordId] when [assess] allows it and returns the next record
  /// in [filter]. [steps] performs the reads and the status move.
  static Future<ApprovalOutcome> approveAndNext(
    String recordId,
    RecordFilter filter, {
    required ApprovalSteps steps,
  }) async {
    final ApprovalOutcome outcome = assess(
      issues: await steps.issues(recordId),
      unresolvedDuplicate: await steps.unresolvedDuplicate(recordId),
      conflictFields: await steps.conflictFields(recordId),
      nextRecordId: await steps.nextUnreviewed(filter, recordId),
    );
    if (outcome is Approved) {
      await steps.markApproved(recordId);
    }
    return outcome;
  }
}

/// Contract entry: approves [recordId] through [steps] unless something
/// blocks, and names the next unreviewed record in [filter].
Future<ApprovalOutcome> approveAndNext(
  String recordId,
  RecordFilter filter, {
  required ApprovalSteps steps,
}) {
  return ApproveRecord.approveAndNext(recordId, filter, steps: steps);
}
