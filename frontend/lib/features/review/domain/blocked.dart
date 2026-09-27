part of 'approval_outcome.dart';

/// Approval refused. [reasons] name the field and what must be fixed.
final class Blocked extends ApprovalOutcome {
  /// Creates a blocked approval.
  Blocked(this.reasons);

  /// Why approval cannot proceed.
  final List<ValidationIssue> reasons;
}
