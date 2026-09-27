import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/records/domain/purge_candidate.dart';
import 'package:tapture/features/records/domain/purge_store.dart';

import '../fakes/fake_purge_store.dart';
import '../fakes/record_results.dart';

void main() {
  final PurgeCandidate old = PurgeCandidate(
    recordId: 'record-1',
    projectId: 'project-1',
    deletedAt: DateTime.utc(2026, 8, 1),
  );

  test('a store lists the bin and removes a candidate from it', () async {
    final PurgeStore store = FakePurgeStore(<PurgeCandidate>[old]);
    expect(okOf(await store.candidates()), <PurgeCandidate>[old]);
    expect(okOf(await store.purge(old)), 1);
    expect(okOf(await store.candidates()), isEmpty);
  });

  test('a store reports a failed removal as a Result, not a throw', () async {
    final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[old]);
    store.failuresById['record-1'] = const StorageFailure(
      message: 'Locked.',
      recoveryAction: 'Try again.',
    );
    expect(failureOf(await store.purge(old)), isA<StorageFailure>());
    expect(okOf(await store.candidates()), hasLength(1));
  });

  test('a store that cannot read the bin says so', () async {
    final FakePurgeStore store = FakePurgeStore()
      ..listFailure = const StorageFailure(
        message: 'Unreadable.',
        recoveryAction: 'Try again.',
      );
    expect(failureOf(await store.candidates()), isA<StorageFailure>());
  });
}
