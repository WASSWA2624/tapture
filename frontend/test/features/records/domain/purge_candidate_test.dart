import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/domain/purge_candidate.dart';

void main() {
  final PurgeCandidate candidate = PurgeCandidate(
    recordId: 'record-1',
    projectId: 'project-1',
    deletedAt: DateTime.utc(2026, 9, 1),
  );

  test('a candidate is not merge-needed unless the store says so', () {
    expect(candidate.mergeNeeded, isFalse);
    expect(candidate.copyWith(mergeNeeded: true).mergeNeeded, isTrue);
  });

  test('candidates with the same fields are equal', () {
    expect(candidate.copyWith(), candidate);
    expect(candidate.copyWith().hashCode, candidate.hashCode);
    expect(candidate.copyWith(recordId: 'record-2'), isNot(candidate));
    expect(
      candidate.copyWith(deletedAt: DateTime.utc(2026, 9, 2)),
      isNot(candidate),
    );
  });

  test('copyWith keeps what it is not given', () {
    final PurgeCandidate moved = candidate.copyWith(projectId: 'project-2');
    expect(moved.recordId, 'record-1');
    expect(moved.projectId, 'project-2');
    expect(moved.deletedAt, candidate.deletedAt);
  });

  test('toString names the record only', () {
    expect(candidate.toString(), 'PurgeCandidate(record-1)');
  });
}
