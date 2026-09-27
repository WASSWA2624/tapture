import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/deleted_record.dart';
import 'package:tapture/features/records/domain/record_summary.dart';

void main() {
  final DateTime deletedAt = DateTime.utc(2026, 9, 1, 12);
  final DeletedRecord binned = DeletedRecord(
    summary: RecordSummary(
      id: 'record-1',
      projectId: 'project-1',
      templateId: 'template-1',
      status: RecordStatus.deleted,
      capturedAt: DateTime.utc(2026, 8, 30),
    ),
    projectName: 'Hospital audit',
    deletedAt: deletedAt,
    reason: 'Duplicate',
  );

  test('a bin row names its record, project and reason', () {
    expect(binned.id, 'record-1');
    expect(binned.projectName, 'Hospital audit');
    expect(binned.reason, 'Duplicate');
    expect(binned.summary.status, RecordStatus.deleted);
  });

  group('daysLeft', () {
    test('is the whole window on the day of the deletion', () {
      expect(binned.daysLeft(now: deletedAt, retentionDays: 30), 30);
      expect(
        binned.daysLeft(
          now: DateTime.utc(2026, 9, 2, 11, 59),
          retentionDays: 30,
        ),
        30,
      );
    });

    test('counts down one per whole day since the deletion', () {
      expect(
        binned.daysLeft(now: DateTime.utc(2026, 9, 2, 12), retentionDays: 30),
        29,
      );
      expect(
        binned.daysLeft(now: DateTime.utc(2026, 9, 21, 13), retentionDays: 30),
        10,
      );
    });

    test('is 0 once the window has passed, never below', () {
      expect(
        binned.daysLeft(now: DateTime.utc(2026, 10, 1, 12), retentionDays: 30),
        0,
      );
      expect(
        binned.daysLeft(now: DateTime.utc(2027, 1, 1), retentionDays: 30),
        0,
      );
      expect(binned.daysLeft(now: deletedAt, retentionDays: 0), 0);
    });

    test('a clock behind the deletion still shows the whole window', () {
      expect(
        binned.daysLeft(now: DateTime.utc(2026, 8, 1), retentionDays: 7),
        7,
      );
    });
  });

  test('rows with the same fields are equal', () {
    expect(binned.copyWith(), binned);
    expect(binned.copyWith().hashCode, binned.hashCode);
    expect(binned.copyWith(reason: 'Wrong site'), isNot(binned));
    expect(binned.copyWith(projectName: 'Other').projectName, 'Other');
  });

  test('toString names the record only', () {
    expect(binned.toString(), 'DeletedRecord(record-1)');
  });
}
