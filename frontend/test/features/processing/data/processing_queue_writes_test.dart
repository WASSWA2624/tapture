import 'dart:convert';

import 'package:drift/drift.dart'
    show BooleanExpressionOperators, OrderClauseGenerator, OrderingTerm, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/processing.dart' as jobs;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
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

  Future<RecordRow> stored(RecordRow record) {
    return (db.select(
      db.records,
    )..where(($RecordsTable t) => t.id.equals(record.id))).getSingle();
  }

  Future<void> setStatus(RecordRow record, RecordStatus status) async {
    await (db.update(db.records)
          ..where(($RecordsTable t) => t.id.equals(record.id)))
        .write(RecordsCompanion(status: Value<String>(status.stored)));
  }

  Future<List<AuditLogData>> history(RecordRow record, String fieldKey) {
    return (db.select(db.auditLog)
          ..where(
            ($AuditLogTable t) =>
                t.entityType.equals('records') &
                t.entityId.equals(record.id) &
                t.fieldKey.equals(fieldKey),
          )
          ..orderBy(<OrderClauseGenerator<$AuditLogTable>>[
            ($AuditLogTable t) => OrderingTerm.asc(t.at),
            ($AuditLogTable t) => OrderingTerm.asc(t.id),
          ]))
        .get();
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

  test('a completed run is written to its record history, stage and provider '
      'but no value', () async {
    final ProcessingQueueWrites queue = writes();
    final String id = _ok(await queue.enqueue(records[0].id));
    await queue.claim(const Duration(minutes: 5));
    _ok(await queue.markStage(id, JobStage.validate));

    _ok(await queue.complete(id));

    final AuditLogData run = (await history(records[0], 'processing')).single;
    expect(run.action, AuditAction.updated);
    expect(run.previousValue, isNull);
    expect(run.newValue, 'completed');
    expect(jsonDecode(run.reason!), <String, Object?>{
      'job': id,
      'stage': 'validate',
    });
    expect(run.device, 'device-a');
    expect(run.at.toUtc(), clock.nowUtc());
  });

  test(
    'a run that stops for good fails its waiting record, in its history',
    () async {
      final ProcessingQueueWrites queue = writes();
      final String id = _ok(await queue.enqueue(records[0].id));

      _ok(await queue.fail(id, 'Timed out.', permanent: false));
      expect(await history(records[0], 'processing'), isEmpty);
      expect((await stored(records[0])).status, RecordStatus.captured.stored);

      _ok(await queue.fail(id, 'Unreadable.', permanent: true));

      final AuditLogData run = (await history(records[0], 'processing')).single;
      expect(run.newValue, 'failed');
      expect(jsonDecode(run.reason!), <String, Object?>{
        'job': id,
        'attempts': 2,
      });
      expect(run.reason, isNot(contains('Unreadable')));
      expect((await stored(records[0])).status, RecordStatus.failed.stored);
      final AuditLogData moved = (await history(records[0], 'status')).single;
      expect(moved.previousValue, RecordStatus.captured.stored);
      expect(moved.newValue, RecordStatus.failed.stored);
      expect(jsonDecode(moved.reason!), <String, Object?>{
        'action': 'failed',
        'job': id,
      });
    },
  );

  test('a failed run leaves a record already reviewed as it was', () async {
    await setStatus(records[0], RecordStatus.needsReview);
    final ProcessingQueueWrites queue = writes();
    final String id = _ok(await queue.enqueue(records[0].id));

    _ok(await queue.fail(id, 'Unreadable.', permanent: true));

    expect((await stored(records[0])).status, RecordStatus.needsReview.stored);
    expect(await history(records[0], 'status'), isEmpty);
    expect((await history(records[0], 'processing')).single.newValue, 'failed');
  });

  test('a retry queues the record its stopped run failed', () async {
    final ProcessingQueueWrites queue = writes();
    final String id = _ok(await queue.enqueue(records[0].id));
    _ok(await queue.fail(id, 'Unreadable.', permanent: true));

    _ok(await queue.retry(id));

    expect((await stored(records[0])).status, RecordStatus.queued.stored);
    final List<AuditLogData> moves = await history(records[0], 'status');
    expect(moves.last.previousValue, RecordStatus.failed.stored);
    expect(moves.last.newValue, RecordStatus.queued.stored);
    expect(jsonDecode(moves.last.reason!), <String, Object?>{
      'action': 'retry',
      'job': id,
    });
  });

  test('requeue resets a finished job to the first stage and queues the '
      'record', () async {
    final ProcessingQueueWrites queue = writes();
    final String id = _ok(await queue.enqueue(records[0].id));
    await queue.claim(const Duration(minutes: 5));
    _ok(await queue.markStage(id, JobStage.validate));
    _ok(await queue.complete(id));
    await (db.update(
      db.processing,
    )..where(($ProcessingTable t) => t.id.equals(id))).write(
      const ProcessingCompanion(
        provider: Value<String?>('backend'),
        model: Value<String?>('default'),
        skipReason: Value<String?>('filled locally'),
        rejections: Value<String?>('["serial is already verified."]'),
      ),
    );
    await setStatus(records[0], RecordStatus.needsReview);
    final int rev = (await stored(records[0])).rev;
    clock.advance(const Duration(minutes: 10));

    expect(_ok(await queue.requeue(records[0].id)), id);

    final ProcessingJobRow job = await row(id);
    expect(job.stage, '');
    expect(job.status, jobs.ProcessingJobStatus.queued);
    expect(job.attempts, 0);
    expect(job.lastError, isNull);
    expect(job.startedAt, isNull);
    expect(job.finishedAt, isNull);
    expect(job.leaseExpiresAt, isNull);
    expect(job.provider, isNull);
    expect(job.model, isNull);
    expect(job.skipReason, isNull);
    expect(job.rejections, isNull);
    expect(job.queuedAt.toUtc(), clock.nowUtc());
    expect(await db.select(db.processing).get(), hasLength(1));

    final RecordRow record = await stored(records[0]);
    expect(record.status, RecordStatus.queued.stored);
    expect(record.rev, rev + 1);
    final AuditLogData moved = (await history(records[0], 'status')).single;
    expect(moved.previousValue, RecordStatus.needsReview.stored);
    expect(moved.newValue, RecordStatus.queued.stored);
    expect(jsonDecode(moved.reason!), <String, Object?>{
      'action': 'requeue',
      'job': id,
    });
    expect(_ok(await queue.claim(const Duration(minutes: 5)))?.id, id);
  });

  test('requeue creates a job for a record that has none', () async {
    final ProcessingQueueWrites queue = writes();

    final String id = _ok(await queue.requeue(records[1].id));

    final ProcessingJobRow job = await row(id);
    expect(job.recordId, records[1].id);
    expect(job.status, jobs.ProcessingJobStatus.queued);
    expect(job.stage, '');
    expect((await stored(records[1])).status, RecordStatus.queued.stored);
    expect(
      (await history(records[1], 'status')).single.previousValue,
      RecordStatus.captured.stored,
    );
  });

  test('an approved record is queued to be processed again', () async {
    await setStatus(records[0], RecordStatus.approved);
    final ProcessingQueueWrites queue = writes();

    _ok(await queue.requeue(records[0].id));

    expect((await stored(records[0])).status, RecordStatus.queued.stored);
    expect(
      (await history(records[0], 'status')).single.previousValue,
      RecordStatus.approved.stored,
    );
  });

  test(
    'a record already queued keeps its status while its job starts over',
    () async {
      final ProcessingQueueWrites queue = writes();
      final String id = _ok(await queue.enqueue(records[0].id));
      _ok(await queue.fail(id, 'Unreadable.', permanent: true));
      await setStatus(records[0], RecordStatus.queued);
      final int rev = (await stored(records[0])).rev;

      expect(_ok(await queue.requeue(records[0].id)), id);

      expect((await row(id)).status, jobs.ProcessingJobStatus.queued);
      final RecordRow record = await stored(records[0]);
      expect(record.status, RecordStatus.queued.stored);
      expect(record.rev, rev);
    },
  );

  for (final RecordStatus refused in <RecordStatus>[
    RecordStatus.deleted,
    RecordStatus.archived,
    RecordStatus.processing,
  ]) {
    test(
      'a ${refused.name} record is refused and nothing is written',
      () async {
        final ProcessingQueueWrites queue = writes();
        final String id = _ok(await queue.enqueue(records[0].id));
        _ok(await queue.fail(id, 'Unreadable.', permanent: true));
        await setStatus(records[0], refused);
        final ProcessingJobRow before = await row(id);
        final RecordRow record = await stored(records[0]);
        final int audits = (await db.select(db.auditLog).get()).length;

        final Result<String> outcome = await queue.requeue(records[0].id);

        expect(outcome, isA<FailureResult<String>>());
        expect(
          (outcome as FailureResult<String>).failure,
          isA<ValidationFailure>(),
        );
        expect(await row(id), before);
        expect(await stored(records[0]), record);
        expect(await db.select(db.auditLog).get(), hasLength(audits));
        expect(await db.select(db.processing).get(), hasLength(1));
      },
    );
  }

  test('a job a runner holds now is not reset under it', () async {
    final ProcessingQueueWrites queue = writes();
    final String id = _ok(await queue.enqueue(records[0].id));
    await queue.claim(const Duration(minutes: 5));
    final ProcessingJobRow running = await row(id);

    final Result<String> outcome = await queue.requeue(records[0].id);

    expect(
      (outcome as FailureResult<String>).failure,
      isA<ValidationFailure>(),
    );
    expect(await row(id), running);
    expect((await stored(records[0])).status, RecordStatus.captured.stored);

    clock.advance(const Duration(minutes: 6));
    expect(_ok(await queue.requeue(records[0].id)), id);
  });

  test('requeue of a missing or empty record id is a failure', () async {
    final ProcessingQueueWrites queue = writes();

    expect(
      (await queue.requeue('missing') as FailureResult<String>).failure,
      isA<StorageFailure>(),
    );
    expect(
      (await queue.requeue('') as FailureResult<String>).failure,
      isA<ValidationFailure>(),
    );
    expect(await db.select(db.processing).get(), isEmpty);
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
