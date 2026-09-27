import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_delete_controller.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;

import '../../../support/factories.dart';
import '../fakes/fake_record_repository.dart';

/// A store whose delete throws for one record instead of failing politely.
/// Only delete is ever called on it.
final class _ThrowingRecords implements RecordRepository {
  _ThrowingRecords(this._inner, this._throwsFor);

  final FakeRecordRepository _inner;
  final String _throwsFor;

  @override
  Future<Result<void>> delete(String id, {required String reason}) {
    if (id == _throwsFor) {
      throw StateError('The disk went away.');
    }
    return _inner.delete(id, reason: reason);
  }

  @override
  Object? noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

const StorageFailure _locked = StorageFailure(
  message: 'That record is locked by a merge.',
  recoveryAction: 'Finish the merge, then try again.',
);

void main() {
  late FakeRecordRepository records;
  late ProviderContainer container;

  ProviderContainer open(RecordRepository store) {
    return ProviderContainer(
      overrides: <Override>[
        recordRepositoryProvider.overrideWith((Ref _) => store),
      ],
    );
  }

  List<String> seed(int count) {
    return <String>[
      for (int n = 1; n <= count; n++)
        records.seedEntry(aRecordEntry(id: 'record-$n')),
    ];
  }

  setUp(() {
    records = FakeRecordRepository();
    container = open(records);
  });

  tearDown(() {
    container.dispose();
    records.dispose();
  });

  RecordDeleteController controller() {
    return container.read(recordDeleteControllerProvider.notifier);
  }

  test('deletes every record to the bin with the operator reason', () async {
    final List<String> ids = seed(3);

    final RecordDeleteOutcome outcome = await controller().delete(ids);

    expect(outcome.succeeded, ids);
    expect(outcome.failed, isEmpty);
    for (final String id in ids) {
      expect(records.entryOf(id)?.status, RecordStatus.deleted);
      expect(records.isTombstoned(id), isTrue);
    }
    final List<DeletedRecord> bin = await records.watchBin().first;
    expect(bin.map((DeletedRecord row) => row.reason).toSet(), <String>{
      RecordDeleteController.operatorReason,
    });
  });

  test('passes a caller reason through to every tombstone', () async {
    final List<String> ids = seed(2);

    await controller().delete(ids, reason: 'Duplicate of record 7.');

    final List<DeletedRecord> bin = await records.watchBin().first;
    expect(bin.map((DeletedRecord row) => row.reason).toSet(), <String>{
      'Duplicate of record 7.',
    });
  });

  test('a repeated id is deleted once', () async {
    final List<String> ids = seed(1);

    final RecordDeleteOutcome outcome = await controller().delete(<String>[
      ids.single,
      ids.single,
    ]);

    expect(outcome.succeeded, ids);
    expect(
      records.writes.where(
        (({String method, String id}) write) => write.method == 'delete',
      ),
      hasLength(1),
    );
  });

  test('nothing asked is nothing written', () async {
    final RecordDeleteOutcome outcome = await controller().delete(<String>[]);

    expect(outcome.succeeded, isEmpty);
    expect(outcome.failed, isEmpty);
    expect(records.writes, isEmpty);
  });

  test('one failure neither stops nor undoes the others', () async {
    final List<String> ids = seed(3);
    records.failuresById[ids[1]] = _locked;

    final RecordDeleteOutcome outcome = await controller().delete(ids);

    expect(outcome.succeeded, <String>[ids[0], ids[2]]);
    expect(outcome.failed, <String, Failure>{ids[1]: _locked});
    expect(records.entryOf(ids[0])?.status, RecordStatus.deleted);
    expect(records.entryOf(ids[1])?.status, RecordStatus.captured);
    expect(records.isTombstoned(ids[1]), isFalse);
    expect(records.entryOf(ids[2])?.status, RecordStatus.deleted);
  });

  test('an illegal delete is reported with the lifecycle reason', () async {
    final String id = records.seedEntry(
      aRecordEntry(id: 'record-1', status: RecordStatus.processing),
    );

    final RecordDeleteOutcome outcome = await controller().delete(<String>[id]);

    expect(outcome.succeeded, isEmpty);
    expect(outcome.failed[id], isA<ValidationFailure>());
    expect(records.entryOf(id)?.status, RecordStatus.processing);
  });

  test('a store that throws counts as a failure for that record', () async {
    final List<String> ids = seed(3);
    final ProviderContainer scoped = open(_ThrowingRecords(records, ids[1]));
    addTearDown(scoped.dispose);

    final RecordDeleteOutcome outcome = await scoped
        .read(recordDeleteControllerProvider.notifier)
        .delete(ids);

    expect(outcome.succeeded, <String>[ids[0], ids[2]]);
    expect(outcome.failed.keys, <String>[ids[1]]);
    expect(outcome.failed[ids[1]]?.message, isNotEmpty);
    expect(records.entryOf(ids[1])?.status, RecordStatus.captured);
    expect(scoped.read(recordDeleteControllerProvider), isFalse);
  });

  test('restore brings deleted records back to where they were', () async {
    final String reviewed = records.seedEntry(
      aRecordEntry(id: 'record-1', status: RecordStatus.needsReview),
    );
    final String approved = records.seedEntry(
      aRecordEntry(id: 'record-2', status: RecordStatus.approved),
    );
    await controller().delete(<String>[reviewed, approved]);

    final RecordDeleteOutcome outcome = await controller().restore(<String>[
      reviewed,
      approved,
    ]);

    expect(outcome.succeeded, <String>[reviewed, approved]);
    expect(records.entryOf(reviewed)?.status, RecordStatus.needsReview);
    expect(records.entryOf(approved)?.status, RecordStatus.approved);
    expect(records.isTombstoned(reviewed), isFalse);
    expect(await records.watchBin().first, isEmpty);
  });

  test('a restore that fails for one record still restores the rest', () async {
    final List<String> ids = seed(2);
    await controller().delete(ids);
    records.failuresById[ids.first] = _locked;

    final RecordDeleteOutcome outcome = await controller().restore(ids);

    expect(outcome.succeeded, <String>[ids.last]);
    expect(outcome.failed, <String, Failure>{ids.first: _locked});
    expect(records.entryOf(ids.first)?.status, RecordStatus.deleted);
    expect(records.entryOf(ids.last)?.status, RecordStatus.captured);
  });

  test('is busy while a delete runs and idle once it ends', () async {
    final List<String> ids = seed(2);
    final List<bool> seen = <bool>[];
    final ProviderSubscription<bool> watching = container.listen<bool>(
      recordDeleteControllerProvider,
      (bool? _, bool busy) => seen.add(busy),
    );
    addTearDown(watching.close);

    final Future<RecordDeleteOutcome> running = controller().delete(ids);
    expect(container.read(recordDeleteControllerProvider), isTrue);
    await running;

    expect(container.read(recordDeleteControllerProvider), isFalse);
    expect(seen, <bool>[true, false]);
  });

  test(
    'an undo still restores after the scope that deleted has gone',
    () async {
      final List<String> ids = seed(1);
      final ProviderContainer scoped = open(records);
      final RecordDeleteController deleting = scoped.read(
        recordDeleteControllerProvider.notifier,
      );
      await deleting.delete(ids);

      scoped.dispose();
      final RecordDeleteOutcome outcome = await deleting.restore(ids);

      expect(outcome.succeeded, ids);
      expect(records.entryOf(ids.single)?.status, RecordStatus.captured);
    },
  );
}
