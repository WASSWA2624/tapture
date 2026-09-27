import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_providers.dart';
import 'package:tapture/features/records/presentation/recycle_bin_controller.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;

import '../../../support/factories.dart';
import '../fakes/fake_purge_store.dart';
import '../fakes/fake_record_repository.dart';
import '../fakes/record_results.dart';

const StorageFailure _locked = StorageFailure(
  message: 'That record is locked by a merge.',
  recoveryAction: 'Finish the merge, then try again.',
);

final DateTime _now = DateTime.utc(2026, 9, 20, 8);

void main() {
  late FakeRecordRepository records;

  setUp(() {
    records = FakeRecordRepository(clock: FixedClock(_now));
  });

  tearDown(() {
    records.dispose();
  });

  /// A container over [repository] (the fake when null) and [job], with the
  /// controller held alive for the test.
  ProviderContainer containerFor({
    RecordRepository? repository,
    PurgeJob? job,
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        recordRepositoryProvider.overrideWith((Ref _) => repository ?? records),
        recordPurgeJobProvider.overrideWith((Ref _) => job),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<RecycleBinActivity> hold = container.listen(
      recycleBinControllerProvider,
      (RecycleBinActivity? _, RecycleBinActivity _) {},
    );
    addTearDown(hold.close);
    return container;
  }

  RecycleBinController controllerOf(ProviderContainer container) {
    return container.read(recycleBinControllerProvider.notifier);
  }

  String binned(String id, {RecordStatus previous = RecordStatus.needsReview}) {
    return records.seedDeleted(
      aRecordEntry(id: id),
      previous: previous,
      deletedAt: _now.subtract(const Duration(days: 2)),
    );
  }

  PurgeCandidate candidate(
    String id, {
    required int daysAgo,
    bool mergeNeeded = false,
  }) {
    return PurgeCandidate(
      recordId: id,
      projectId: 'project-1',
      deletedAt: _now.subtract(Duration(days: daysAgo)),
      mergeNeeded: mergeNeeded,
    );
  }

  group('the recycle bin list', () {
    test('lists the deleted records and follows a restore', () async {
      final String id = binned('record-1');
      final ProviderContainer container = containerFor();
      final List<List<String>> seen = <List<String>>[];
      final ProviderSubscription<AsyncValue<List<DeletedRecord>>> listing =
          container.listen(recycleBinProvider, (
            AsyncValue<List<DeletedRecord>>? _,
            AsyncValue<List<DeletedRecord>> next,
          ) {
            final List<DeletedRecord>? rows = next.value;
            if (rows != null) {
              seen.add(<String>[for (final DeletedRecord row in rows) row.id]);
            }
          }, fireImmediately: true);
      addTearDown(listing.close);
      await pumpEventQueue();
      expect(seen.last, <String>[id]);

      okOf(await controllerOf(container).restore(id));
      await pumpEventQueue();

      expect(seen.last, isEmpty);
    });

    test('surfaces a read failure without retrying', () async {
      records.readFailure = _locked;
      final ProviderContainer container = containerFor();
      final ProviderSubscription<AsyncValue<List<DeletedRecord>>> listing =
          container.listen(
            recycleBinProvider,
            (
              AsyncValue<List<DeletedRecord>>? _,
              AsyncValue<List<DeletedRecord>> _,
            ) {},
          );
      addTearDown(listing.close);
      await pumpEventQueue();

      final AsyncValue<List<DeletedRecord>> value = container.read(
        recycleBinProvider,
      );
      expect(value.hasError, isTrue);
      expect(value.error, _locked);
    });
  });

  group('restore', () {
    test(
      'brings the record back to the status it had and out of the bin',
      () async {
        final String id = binned('record-1', previous: RecordStatus.approved);
        final ProviderContainer container = containerFor();

        okOf(await controllerOf(container).restore(id));

        expect(records.entryOf(id)!.status, RecordStatus.approved);
        expect(records.isTombstoned(id), isFalse);
        expect(records.writes.last, (method: 'restore', id: id));
      },
    );

    test(
      'returns why a restore failed and leaves the record in the bin',
      () async {
        final String id = binned('record-1');
        records.failuresById[id] = _locked;
        final ProviderContainer container = containerFor();

        expect(failureOf(await controllerOf(container).restore(id)), _locked);
        expect(records.entryOf(id)!.status, RecordStatus.deleted);
        expect(records.isTombstoned(id), isTrue);
      },
    );

    test('turns a store that throws into a failure', () async {
      final ProviderContainer container = containerFor(
        repository: _ThrowingRestore(),
      );

      final Failure failure = failureOf(
        await controllerOf(container).restore('record-1'),
      );

      expect(failure, isA<ProviderFailure>());
      expect(controllerOf(container).isRestoring('record-1'), isFalse);
    });

    test(
      'marks the record while it is restored, and refuses a second press',
      () async {
        final _HeldRestore held = _HeldRestore();
        final ProviderContainer container = containerFor(repository: held);
        final RecycleBinController controller = controllerOf(container);

        final Future<Result<void>> first = controller.restore('record-1');
        expect(controller.isRestoring('record-1'), isTrue);
        expect(container.read(recycleBinControllerProvider).restoring, <String>{
          'record-1',
        });
        final Failure second = failureOf(await controller.restore('record-1'));
        expect(second.message, Copy.recycleBinRestoring);

        held.release.complete(const Success<void>(null));
        okOf(await first);
        expect(controller.isRestoring('record-1'), isFalse);
        expect(held.calls, 1);
      },
    );
  });

  group('empty now', () {
    test('is refused, with the reason, where no purge runs', () async {
      final ProviderContainer container = containerFor();

      final Failure failure = failureOf(
        await controllerOf(container).emptyNow(),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, Copy.recycleBinEmptyUnavailable);
      expect(failure.recoveryAction, Copy.recycleBinEmptyUnavailableAction);
      expect(container.read(recycleBinControllerProvider).emptying, isFalse);
    });

    test(
      'purges every record however recent, but keeps one a merge needs',
      () async {
        final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[
          candidate('recent', daysAgo: 1),
          candidate('old', daysAgo: 40),
          candidate('shared', daysAgo: 60, mergeNeeded: true),
        ])..filesById['old'] = 3;
        final ProviderContainer container = containerFor(
          job: PurgeJob(
            store: store,
            clock: FixedClock(_now),
            retentionDays: 30,
          ),
        );

        final PurgeReport report = okOf(
          await controllerOf(container).emptyNow(),
        );

        expect(store.purged, <String>['recent', 'old']);
        expect(report.purged, 2);
        expect(report.skippedRecent, 0);
        expect(report.skippedMergeNeeded, 1);
        expect(report.filesRemoved, 4);
        expect(report.failed, 0);
        expect(store.remaining.single.recordId, 'shared');
      },
    );

    test('counts a record that fails and goes on with the rest', () async {
      final FakePurgeStore store =
          FakePurgeStore(<PurgeCandidate>[
              candidate('a', daysAgo: 1),
              candidate('b', daysAgo: 1),
              candidate('c', daysAgo: 1),
            ])
            ..failuresById['a'] = _locked
            ..throwsFor.add('b');
      final ProviderContainer container = containerFor(
        job: PurgeJob(store: store, clock: FixedClock(_now), retentionDays: 30),
      );

      final PurgeReport report = okOf(await controllerOf(container).emptyNow());

      expect(report.purged, 1);
      expect(report.failed, 2);
      expect(store.purged, <String>['c']);
    });

    test('fails when the bin cannot be read', () async {
      final FakePurgeStore store = FakePurgeStore()..listFailure = _locked;
      final ProviderContainer container = containerFor(
        job: PurgeJob(store: store, clock: FixedClock(_now), retentionDays: 30),
      );

      expect(failureOf(await controllerOf(container).emptyNow()), _locked);
      expect(container.read(recycleBinControllerProvider).emptying, isFalse);
    });

    test(
      'says it is emptying while it runs, and refuses a second press',
      () async {
        final _HeldPurgeStore store = _HeldPurgeStore();
        final ProviderContainer container = containerFor(
          job: PurgeJob(
            store: store,
            clock: FixedClock(_now),
            retentionDays: 30,
          ),
        );
        final RecycleBinController controller = controllerOf(container);

        final Future<Result<PurgeReport>> first = controller.emptyNow();
        expect(container.read(recycleBinControllerProvider).emptying, isTrue);
        final Failure second = failureOf(await controller.emptyNow());
        expect(second.message, Copy.recycleBinEmptying);

        store.release.complete(
          const Success<List<PurgeCandidate>>(<PurgeCandidate>[]),
        );
        expect(okOf(await first), PurgeReport.none);
        expect(container.read(recycleBinControllerProvider).emptying, isFalse);
        expect(store.listed, 1);
      },
    );
  });
}

/// A store whose restore throws.
final class _ThrowingRestore implements RecordRepository {
  @override
  Future<Result<void>> restore(String id) async {
    throw StateError('store broke on $id');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A store whose restore waits for the test to release it.
final class _HeldRestore implements RecordRepository {
  final Completer<Result<void>> release = Completer<Result<void>>();
  int calls = 0;

  @override
  Future<Result<void>> restore(String id) {
    calls++;
    return release.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A purge store whose listing waits for the test to release it.
final class _HeldPurgeStore implements PurgeStore {
  final Completer<Result<List<PurgeCandidate>>> release =
      Completer<Result<List<PurgeCandidate>>>();
  int listed = 0;

  @override
  Future<Result<List<PurgeCandidate>>> candidates() {
    listed++;
    return release.future;
  }

  @override
  Future<Result<int>> purge(PurgeCandidate candidate) async {
    return const Success<int>(0);
  }
}
