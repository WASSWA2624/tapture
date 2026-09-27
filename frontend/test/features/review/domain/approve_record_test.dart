import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/validation/severity.dart';
import 'package:tapture/core/validation/validation_issue.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/record_filter.dart';
import 'package:tapture/features/review/domain/approval_outcome.dart';
import 'package:tapture/features/review/domain/approval_steps.dart';
import 'package:tapture/features/review/domain/approve_record.dart';

void main() {
  test('a validation error blocks and names the field', () {
    final ApprovalOutcome outcome = ApproveRecord.assess(
      issues: const <ValidationIssue>[
        ValidationIssue('serial', Severity.error, 'Serial is required.'),
      ],
      unresolvedDuplicate: false,
      conflictFields: const <String>[],
      nextRecordId: 'next',
    );
    expect(outcome, isA<Blocked>());
    final Blocked blocked = outcome as Blocked;
    expect(blocked.reasons.single.fieldKey, 'serial');
    expect(blocked.reasons.single.message, 'Serial is required.');
  });

  test('an unresolved duplicate blocks', () {
    final Blocked blocked =
        ApproveRecord.assess(
              issues: const <ValidationIssue>[],
              unresolvedDuplicate: true,
              conflictFields: const <String>[],
              nextRecordId: 'next',
            )
            as Blocked;
    expect(blocked.reasons.single.message, Copy.reviewBlockedDuplicate);
  });

  test('an unresolved conflict blocks and names the field', () {
    final Blocked blocked =
        ApproveRecord.assess(
              issues: const <ValidationIssue>[],
              unresolvedDuplicate: false,
              conflictFields: const <String>['note'],
              nextRecordId: 'next',
            )
            as Blocked;
    expect(blocked.reasons.single.fieldKey, 'note');
    expect(blocked.reasons.single.message, contains('note'));
  });

  test('a clean record is approved and names the next one', () async {
    final _Steps steps = _Steps();
    final ApprovalOutcome outcome = await approveAndNext(
      'r1',
      RecordFilter.forStatus(RecordStatus.needsReview),
      steps: steps,
    );
    expect(outcome, isA<Approved>());
    expect((outcome as Approved).nextRecordId, 'r2');
    expect(steps.approved, 'r1');
  });

  test('a warning does not block', () {
    final ApprovalOutcome outcome = ApproveRecord.assess(
      issues: const <ValidationIssue>[
        ValidationIssue('note', Severity.warning, 'Note is recommended.'),
      ],
      unresolvedDuplicate: false,
      conflictFields: const <String>[],
      nextRecordId: null,
    );
    expect(outcome, isA<Approved>());
    expect((outcome as Approved).nextRecordId, isNull);
  });
}

final class _Steps implements ApprovalSteps {
  String? approved;

  @override
  Future<List<String>> conflictFields(String recordId) async =>
      const <String>[];

  @override
  Future<List<ValidationIssue>> issues(String recordId) async =>
      const <ValidationIssue>[];

  @override
  Future<void> markApproved(String recordId) async {
    approved = recordId;
  }

  @override
  Future<String?> nextUnreviewed(RecordFilter filter, String recordId) async =>
      'r2';

  @override
  Future<bool> unresolvedDuplicate(String recordId) async => false;
}
