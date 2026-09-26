import 'package:drift/drift.dart'
    show OrderClauseGenerator, OrderingTerm, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/processing.dart' as jobs;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/data/processing_queue_queries.dart';
import 'package:tapture/features/processing/data/processing_queue_writes.dart';
import 'package:tapture/features/processing/domain/job_retry.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';

void main() {
  late AppDatabase db;
  late _MovingClock clock;
  late List<RecordRow> records;

  setUp(() async {
    db = await seededDatabase(records: 3);
    clock = _MovingClock(DateTime.utc(2026, 9, 26, 8));
    records =
        await (db.select(db.records)
              ..orderBy(<OrderClauseGenerator<$RecordsTable>>[
                ($RecordsTable t) => OrderingTerm.asc(t.id),
              ]))
            .get();
  });

  tearDown(() => db.close());

  ProcessingQueueWrites writes({int concurrency = 3}) {
    final SettingsStore settings = SettingsStore.fake(
      stored: <String, Object?>{SettingKeys.aiConcurrency.name: concurrency},
    );
    return ProcessingQueueWrites(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
      settings: settings,
      queries: ProcessingQueueQueries(db: db, clock: clock, settings: settings),
    );
  }

  Future<ProcessingJobRow> row(String id) {
    return (db.select(
      db.processing,
    )..where(($ProcessingTable t) => t.id.equals(id))).getSingle();
  }

  Future<void> placeIn(RecordRow record, String contextJson) async {
    await (db.update(db.records)
          ..where(($RecordsTable t) => t.id.equals(record.id)))
        .write(RecordsCompanion(contextJson: Value<String>(contextJson)));
  }

  test('pending records are queued once each', () async {
    final ProcessingQueueWrites queue = writes();

    expect(_ok(await queue.enqueuePending()), 3);
    expect(_ok(await queue.enqueuePending()), 0);
    expect(await db.select(db.processing).get(), hasLength(3));
  });

  test('queuing a group leaves the other groups alone', () async {
    await placeIn(records[0], '{"room":"Plant room"}');
    await placeIn(records[1], '{"room":"Store"}');
    final ProcessingQueueWrites queue = writes();

    expect(_ok(await queue.enqueuePending(groupLabels: <String>['Store'])), 1);

    final ProcessingJobRow job = await db.select(db.processing).getSingle();
    expect(job.recordId, records[1].id);
  });

  test('a record is queued at most once', () async {
    final ProcessingQueueWrites queue = writes();
    final String first = _ok(await queue.enqueue(records[0].id));

    expect(_ok(await queue.enqueue(records[0].id)), first);
    expect(await queue.enqueue(''), isA<FailureResult<String>>());
  });

  test('a claim takes the oldest job and leases it', () async {
    final ProcessingQueueWrites queue = writes();
    final String first = _ok(await queue.enqueue(records[0].id));
    clock.advance(const Duration(seconds: 1));
    await queue.enqueue(records[1].id);

    final ProcessingJob? claimed = _ok(
      await queue.claim(const Duration(minutes: 5)),
    );

    expect(claimed?.id, first);
    final ProcessingJobRow stored = await row(first);
    expect(stored.status, jobs.ProcessingJobStatus.running);
    expect(
      stored.leaseExpiresAt?.toUtc(),
      clock.nowUtc().add(const Duration(minutes: 5)),
    );
    expect(stored.updatedByDevice, 'device-a');
  });

  test('nothing is claimed while the running jobs reach the cap', () async {
    final ProcessingQueueWrites queue = writes(concurrency: 1);
    await queue.enqueuePending();

    expect(_ok(await queue.claim(const Duration(minutes: 5))), isNotNull);
    expect(_ok(await queue.claim(const Duration(minutes: 5))), isNull);
  });

  test('an expired lease returns the job to the queue', () async {
    final ProcessingQueueWrites queue = writes(concurrency: 1);
    await queue.enqueue(records[0].id);
    final ProcessingJob? first = _ok(
      await queue.claim(const Duration(minutes: 1)),
    );

    clock.advance(const Duration(minutes: 2));
    final ProcessingJob? again = _ok(
      await queue.claim(const Duration(minutes: 1)),
    );

    expect(again?.id, first?.id);
  });

  test('a claim can be limited to a project and to groups', () async {
    await placeIn(records[2], '{"room":"Store"}');
    final ProcessingQueueWrites queue = writes();
    await queue.enqueuePending();

    expect(
      _ok(
        await queue.claim(
          const Duration(minutes: 5),
          projectId: 'another-project',
        ),
      ),
      isNull,
    );
    final ProcessingJob? store = _ok(
      await queue.claim(
        const Duration(minutes: 5),
        projectId: records[2].projectId,
        groupLabels: <String>['Store'],
      ),
    );
    expect(store?.recordId, records[2].id);
  });

  test('a job past the requested stage is passed over', () async {
    final ProcessingQueueWrites queue = writes();
    final String read = _ok(await queue.enqueue(records[0].id));
    _ok(await queue.markStage(read, JobStage.onDevice));
    clock.advance(const Duration(seconds: 1));
    final String fresh = _ok(await queue.enqueue(records[1].id));

    final ProcessingJob? claimed = _ok(
      await queue.claim(
        const Duration(minutes: 5),
        unfinished: JobStage.onDevice,
      ),
    );

    expect(claimed?.id, fresh);
    expect((await row(read)).stage, 'onDevice');
  });

  test('a job set aside by the batch is passed over', () async {
    final ProcessingQueueWrites queue = writes();
    final String aside = _ok(await queue.enqueue(records[0].id));
    clock.advance(const Duration(seconds: 1));
    final String next = _ok(await queue.enqueue(records[1].id));

    final ProcessingJob? claimed = _ok(
      await queue.claim(const Duration(minutes: 5), skip: <String>{aside}),
    );

    expect(claimed?.id, next);
    expect((await row(aside)).status, jobs.ProcessingJobStatus.queued);
  });

  test('a transient failure waits out its backoff before a retry', () async {
    final ProcessingQueueWrites queue = writes();
    final String id = _ok(await queue.enqueue(records[0].id));
    await queue.claim(const Duration(minutes: 5));

    _ok(await queue.fail(id, 'The provider timed out.', permanent: false));

    final ProcessingJobRow waiting = await row(id);
    expect(waiting.status, jobs.ProcessingJobStatus.queued);
    expect(waiting.attempts, 1);
    expect(waiting.lastError, 'The provider timed out.');
    expect(_ok(await queue.claim(const Duration(minutes: 5))), isNull);

    clock.advance(JobRetry.backoffFor(1));
    expect(_ok(await queue.claim(const Duration(minutes: 5)))?.id, id);
  });

  test('a permanent failure, or the last attempt, stops the job', () async {
    final ProcessingQueueWrites queue = writes();
    final String permanent = _ok(await queue.enqueue(records[0].id));
    final String tired = _ok(await queue.enqueue(records[1].id));

    _ok(await queue.fail(permanent, 'Unreadable.', permanent: true));
    for (var i = 0; i < AppConstants.processing.maxAttempts; i++) {
      _ok(await queue.fail(tired, 'Timed out.', permanent: false));
    }

    expect((await row(permanent)).status, jobs.ProcessingJobStatus.failed);
    final ProcessingJobRow stopped = await row(tired);
    expect(stopped.status, jobs.ProcessingJobStatus.failed);
    expect(stopped.attempts, AppConstants.processing.maxAttempts);
    expect(stopped.finishedAt, isNotNull);
  });

  test('a retry starts a stopped job afresh and keeps its stage', () async {
    final ProcessingQueueWrites queue = writes();
    final String id = _ok(await queue.enqueue(records[0].id));
    _ok(await queue.markStage(id, JobStage.detect));
    _ok(await queue.fail(id, 'Unreadable.', permanent: true));

    _ok(await queue.retry(id));

    final ProcessingJobRow retried = await row(id);
    expect(retried.status, jobs.ProcessingJobStatus.queued);
    expect(retried.attempts, 0);
    expect(retried.lastError, isNull);
    expect(retried.stage, 'detect');
  });

  test('complete finishes the job and drops its lease', () async {
    final ProcessingQueueWrites queue = writes();
    final String id = _ok(await queue.enqueue(records[0].id));
    await queue.claim(const Duration(minutes: 5));
    final int rev = (await row(id)).rev;

    _ok(await queue.complete(id));

    final ProcessingJobRow done = await row(id);
    expect(done.status, jobs.ProcessingJobStatus.completed);
    expect(done.leaseExpiresAt, isNull);
    expect(done.finishedAt?.toUtc(), clock.nowUtc());
    expect(done.rev, rev + 1);
  });

  test('release requeues a job and a missing job is a failure', () async {
    final ProcessingQueueWrites queue = writes();
    final String id = _ok(await queue.enqueue(records[0].id));
    await queue.claim(const Duration(minutes: 5));

    _ok(await queue.release(id));

    expect((await row(id)).status, jobs.ProcessingJobStatus.queued);
    expect(await queue.release('missing'), isA<FailureResult<void>>());
    expect(
      await queue.markStage('missing', JobStage.prepare),
      isA<FailureResult<ProcessingJob>>(),
    );
  });
}

/// A clock a test moves forward by hand.
final class _MovingClock implements Clock {
  _MovingClock(this._now);

  DateTime _now;

  void advance(Duration by) => _now = _now.add(by);

  @override
  DateTime nowUtc() => _now;

  @override
  DateTime today() => DateTime.utc(_now.year, _now.month, _now.day);

  @override
  Duration get offset => Duration.zero;
}

T _ok<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw TestFailure(failure.message),
    (T value) => value,
  );
}
