import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/processing/processing.dart'
    show processingRepositoryProvider;
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_bulk_controller.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;

import '../../../support/factories.dart';
import '../../../support/fakes/fake_processing_repository.dart';
import '../fakes/fake_record_repository.dart';

const String _project = 'project-1';

const StorageFailure _locked = StorageFailure(
  message: 'That record is locked by a merge.',
  recoveryAction: 'Finish the merge, then try again.',
);

void main() {
  late FakeRecordRepository records;
  late FakeProcessingRepository processing;

  setUp(() {
    records = FakeRecordRepository();
    processing = FakeProcessingRepository();
  });

  tearDown(() {
    records.dispose();
    processing.dispose();
  });

  /// A container over [repository] (the fake when null) and the processing
  /// fake, with [_project]'s controller held alive for the test.
  ProviderContainer containerFor({RecordRepository? repository}) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        recordRepositoryProvider.overrideWith((Ref _) => repository ?? records),
        processingRepositoryProvider.overrideWith((Ref _) => processing),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<RecordBulkOperation?> hold = container.listen(
      recordBulkControllerProvider(_project),
      (RecordBulkOperation? _, RecordBulkOperation? _) {},
    );
    addTearDown(hold.close);
    return container;
  }

  RecordBulkController controllerOf(ProviderContainer container) {
    return container.read(recordBulkControllerProvider(_project).notifier);
  }

  String seed(String id, RecordStatus status) {
    return records.seedEntry(aRecordEntry(id: id, status: status));
  }

  group('approve', () {
    test(
      'approves each record in the order asked, with the bulk reason',
      () async {
        final List<String> ids = <String>[
          seed('record-1', RecordStatus.needsReview),
          seed('record-2', RecordStatus.extracted),
          seed('record-3', RecordStatus.needsReview),
        ];
        final ProviderContainer container = containerFor();

        final RecordBulkOutcome outcome = await controllerOf(
          container,
        ).approve(ids);

        expect(outcome.succeeded, ids);
        expect(outcome.failed, isEmpty);
        for (final String id in ids) {
          final RecordEntry entry = records.entryOf(id)!;
          expect(entry.status, RecordStatus.approved);
          expect(entry.approvedBy, 'Test operator');
          final RecordHistoryEvent last = records.historyOf(id).last;
          expect(last.kind, RecordHistoryKind.statusChanged);
          expect(last.next, RecordStatus.approved.stored);
          expect(last.reason, RecordBulkController.approveReason);
        }
        expect(<String>[
          for (final ({String method, String id}) write in records.writes)
            write.id,
        ], ids);
      },
    );

    test(
      'approves a repeated record once, and nothing asked writes nothing',
      () async {
        final String id = seed('record-1', RecordStatus.needsReview);
        final ProviderContainer container = containerFor();

        final RecordBulkOutcome none = await controllerOf(
          container,
        ).approve(const <String>[]);
        expect(none.succeeded, isEmpty);
        expect(none.failed, isEmpty);
        expect(records.writes, isEmpty);

        final RecordBulkOutcome once = await controllerOf(
          container,
        ).approve(<String>[id, id]);
        expect(once.succeeded, <String>[id]);
        expect(records.writes, hasLength(1));
      },
    );

    test(
      'follows the lifecycle: a captured record fails validation and is left as it was',
      () async {
        final String ready = seed('record-1', RecordStatus.needsReview);
        final String captured = seed('record-2', RecordStatus.captured);
        final RecordEntry before = records.entryOf(captured)!;
        final int history = records.historyOf(captured).length;
        final ProviderContainer container = containerFor();

        final RecordBulkOutcome outcome = await controllerOf(
          container,
        ).approve(<String>[ready, captured]);

        expect(outcome.succeeded, <String>[ready]);
        expect(outcome.failed.keys, <String>[captured]);
        expect(outcome.failed[captured], isA<ValidationFailure>());
        expect(records.entryOf(captured), before);
        expect(records.historyOf(captured), hasLength(history));
      },
    );
  });

  group('archive', () {
    test('archives each record with the bulk reason', () async {
      final List<String> ids = <String>[
        seed('record-1', RecordStatus.captured),
        seed('record-2', RecordStatus.approved),
      ];
      final ProviderContainer container = containerFor();

      final RecordBulkOutcome outcome = await controllerOf(
        container,
      ).archive(ids);

      expect(outcome.succeeded, ids);
      for (final String id in ids) {
        expect(records.entryOf(id)!.status, RecordStatus.archived);
        expect(
          records.historyOf(id).last.reason,
          RecordBulkController.archiveReason,
        );
      }
    });

    test('refuses a record that is processing and archives the rest', () async {
      final String busy = seed('record-1', RecordStatus.processing);
      final String idle = seed('record-2', RecordStatus.needsReview);
      final ProviderContainer container = containerFor();

      final RecordBulkOutcome outcome = await controllerOf(
        container,
      ).archive(<String>[busy, idle]);

      expect(outcome.succeeded, <String>[idle]);
      expect(outcome.failed[busy], isA<ValidationFailure>());
      expect(records.entryOf(busy)!.status, RecordStatus.processing);
    });
  });

  group('one failure', () {
    test('neither stops nor undoes the others', () async {
      final List<String> ids = <String>[
        seed('record-1', RecordStatus.needsReview),
        seed('record-2', RecordStatus.needsReview),
        seed('record-3', RecordStatus.needsReview),
      ];
      records.failuresById['record-2'] = _locked;
      final RecordEntry before = records.entryOf('record-2')!;
      final int history = records.historyOf('record-2').length;
      final ProviderContainer container = containerFor();

      final RecordBulkOutcome outcome = await controllerOf(
        container,
      ).archive(ids);

      expect(outcome.succeeded, <String>['record-1', 'record-3']);
      expect(outcome.failed, <String, Failure>{'record-2': _locked});
      expect(records.entryOf('record-1')!.status, RecordStatus.archived);
      expect(records.entryOf('record-3')!.status, RecordStatus.archived);
      expect(records.entryOf('record-2'), before);
      expect(records.historyOf('record-2'), hasLength(history));
    });

    test('from a store that throws counts for that record only', () async {
      seed('record-1', RecordStatus.needsReview);
      seed('record-2', RecordStatus.needsReview);
      final ProviderContainer container = containerFor(
        repository: _ThrowingFor(records, 'record-1'),
      );

      final RecordBulkOutcome outcome = await controllerOf(
        container,
      ).approve(<String>['record-1', 'record-2']);

      expect(outcome.succeeded, <String>['record-2']);
      expect(outcome.failed['record-1'], isA<ProviderFailure>());
      expect(records.entryOf('record-2')!.status, RecordStatus.approved);
    });
  });

  group('process again', () {
    test(
      'queues each record through processing and reports the refused one',
      () async {
        processing.recordStatuses
          ..['record-1'] = RecordStatus.needsReview
          ..['record-2'] = RecordStatus.approved
          ..['record-3'] = RecordStatus.processing;
        processing.requeueFailures['record-2'] = _locked;
        final ProviderContainer container = containerFor();

        final RecordBulkOutcome outcome = await controllerOf(
          container,
        ).reprocess(<String>['record-1', 'record-2', 'record-3']);

        expect(outcome.succeeded, <String>['record-1']);
        expect(outcome.failed['record-2'], _locked);
        expect(outcome.failed['record-3'], isA<ValidationFailure>());
        expect(processing.requeued, <String>['record-1']);
        expect(processing.recordStatuses['record-1'], RecordStatus.queued);
        expect(processing.recordStatuses['record-2'], RecordStatus.approved);
        expect(processing.stored.single.recordId, 'record-1');
      },
    );
  });

  group('the state', () {
    test('names the running action, then clears', () async {
      final _HeldTransition held = _HeldTransition();
      final ProviderContainer container = containerFor(repository: held);
      final RecordBulkController controller = controllerOf(container);

      expect(controller.isBusy, isFalse);
      final Future<RecordBulkOutcome> running = controller.archive(<String>[
        'record-1',
      ]);
      expect(
        container.read(recordBulkControllerProvider(_project)),
        RecordBulkOperation.archive,
      );
      expect(controller.isBusy, isTrue);

      held.release.complete(const Success<void>(null));
      expect((await running).succeeded, <String>['record-1']);
      expect(container.read(recordBulkControllerProvider(_project)), isNull);
    });

    test('refuses a second action while one runs, naming why', () async {
      final _HeldTransition held = _HeldTransition();
      final ProviderContainer container = containerFor(repository: held);
      final RecordBulkController controller = controllerOf(container);

      final Future<RecordBulkOutcome> running = controller.approve(<String>[
        'record-1',
      ]);
      final RecordBulkOutcome refused = await controller.archive(<String>[
        'record-2',
        'record-3',
      ]);

      expect(refused.succeeded, isEmpty);
      expect(refused.failed.keys, <String>['record-2', 'record-3']);
      expect(refused.failed['record-2']!.message, Copy.recordsBulkBusy);
      held.release.complete(const Success<void>(null));
      await running;
      expect(held.asked, <String>['record-1']);
    });

    test('is kept per project', () async {
      final _HeldTransition held = _HeldTransition();
      final ProviderContainer container = containerFor(repository: held);
      final ProviderSubscription<RecordBulkOperation?> other = container.listen(
        recordBulkControllerProvider('project-2'),
        (RecordBulkOperation? _, RecordBulkOperation? _) {},
      );
      addTearDown(other.close);

      final Future<RecordBulkOutcome> running = controllerOf(
        container,
      ).approve(<String>['record-1']);

      expect(container.read(recordBulkControllerProvider('project-2')), isNull);
      held.release.complete(const Success<void>(null));
      await running;
    });
  });
}

/// The fake store, except that a status move of [id] throws.
final class _ThrowingFor implements RecordRepository {
  _ThrowingFor(this._inner, this._id);

  final RecordRepository _inner;
  final String _id;

  @override
  Future<Result<void>> transition(
    String id,
    RecordStatus to, {
    String? reason,
  }) async {
    if (id == _id) {
      throw StateError('store broke on $id');
    }
    return _inner.transition(id, to, reason: reason);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A store whose status moves wait for the test to release them.
final class _HeldTransition implements RecordRepository {
  final Completer<Result<void>> release = Completer<Result<void>>();
  final List<String> asked = <String>[];

  @override
  Future<Result<void>> transition(
    String id,
    RecordStatus to, {
    String? reason,
  }) {
    asked.add(id);
    return release.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
