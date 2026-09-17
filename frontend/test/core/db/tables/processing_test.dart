import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/processing.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final DateTime t1 = t0.add(const Duration(seconds: 1));

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'claim takes the oldest queued job and refuses a second worker',
    () async {
      final ProcessingJobRow older = _ok(
        await upsertProcessingJob(
          db,
          row: _job(recordId: 'r-old', queuedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertProcessingJob(
          db,
          row: _job(recordId: 'r-new', queuedAt: t1),
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final ProcessingJobRow first = _ok(
        await claimNextProcessingJob(
          db,
          clock: FixedClock(t1),
          deviceId: 'worker-1',
          ids: ids,
        ),
      )!;
      expect(first.id, older.id);
      expect(first.status, ProcessingJobStatus.running);
      expect(first.recordId, 'r-old');

      final List<ProcessingJobRow?> concurrent =
          await Future.wait(<Future<ProcessingJobRow?>>[
            claimNextProcessingJob(
              db,
              clock: FixedClock(t1),
              deviceId: 'worker-2',
              ids: ids,
            ).then(_ok),
            claimNextProcessingJob(
              db,
              clock: FixedClock(t1),
              deviceId: 'worker-3',
              ids: ids,
            ).then(_ok),
          ]);
      expect(
        concurrent.where((ProcessingJobRow? job) => job?.id == older.id),
        isEmpty,
      );
      expect(
        concurrent
            .whereType<ProcessingJobRow>()
            .map((ProcessingJobRow job) => job.id)
            .toSet(),
        hasLength(1),
      );

      final List<QueryRow> plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM processing_jobs '
            "WHERE status = 'queued' ORDER BY queued_at ASC",
          )
          .get();
      expect(
        plan.map((QueryRow row) => row.read<String>('detail')).join('; '),
        contains('processing_jobs_by_status'),
      );
    },
  );

  test('a retry increments attempts and keeps every earlier result', () async {
    final ProcessingJobRow job = _ok(
      await upsertProcessingJob(
        db,
        row: _job(recordId: 'r1', queuedAt: t0),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    _ok(
      await claimNextProcessingJob(
        db,
        clock: FixedClock(t0),
        deviceId: 'worker-1',
        ids: ids,
      ),
    );
    final ProcessingResult first = _ok(
      await insertProcessingResult(
        db,
        row: ProcessingResultsCompanion(
          jobId: Value<String>(job.id),
          requestSummary: const Value<String>('{"photos":1}'),
          rawResponse: const Value<String>('{"v":1}'),
          parsedOk: const Value<bool>(false),
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );

    final ProcessingJobRow retried = _ok(
      await retryProcessingJob(
        db,
        id: job.id,
        clock: FixedClock(t1),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    expect(retried.attempts, 1);
    expect(retried.status, ProcessingJobStatus.queued);

    _ok(
      await claimNextProcessingJob(
        db,
        clock: FixedClock(t1),
        deviceId: 'worker-1',
        ids: ids,
      ),
    );
    _ok(
      await insertProcessingResult(
        db,
        row: ProcessingResultsCompanion(
          jobId: Value<String>(job.id),
          requestSummary: const Value<String>('{"photos":1}'),
          rawResponse: const Value<String>('{"v":2}'),
          parsedOk: const Value<bool>(true),
        ),
        clock: FixedClock(t1),
        deviceId: 'device-a',
        ids: ids,
      ),
    );

    final List<String> bodies = _ok(
      await listProcessingResults(db, jobId: job.id),
    ).map((ProcessingResult row) => row.rawResponse).toList();
    expect(bodies, <String>['{"v":1}', '{"v":2}']);

    final Result<ProcessingResult> rewritten = await insertProcessingResult(
      db,
      row: ProcessingResultsCompanion(
        id: Value<String>(first.id),
        jobId: Value<String>(job.id),
        requestSummary: const Value<String>('{"photos":1}'),
        rawResponse: const Value<String>('changed'),
        parsedOk: const Value<bool>(true),
      ),
      clock: FixedClock(t1),
      deviceId: 'device-a',
      ids: ids,
    );
    expect(
      rewritten.fold((Failure failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );
    expect(
      (await (db.select(db.processingResults)..where(
                ($ProcessingResultsTable tbl) => tbl.id.equals(first.id),
              ))
              .getSingle())
          .rawResponse,
      '{"v":1}',
    );
  });

  test('version 8 creates the processing tables with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_processing_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final File seed = File('${directory.path}/tapture.sqlite');
    _seedVersion1(seed);

    final AppDatabase upgraded = AppDatabase.open(
      directoryPath: directory.path,
    );
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();

    expect(
      await _columns(upgraded, 'processing_jobs'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'record_id',
        'stage',
        'status',
        'attempts',
        'last_error',
        'queued_at',
        'started_at',
        'finished_at',
        'provider',
        'model',
      ]),
    );
    expect(
      await _columns(upgraded, 'processing_results'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'job_id',
        'request_summary',
        'raw_response',
        'parsed_ok',
        'tokens_or_cost',
      ]),
    );
  });
}

ProcessingCompanion _job({
  required String recordId,
  required DateTime queuedAt,
}) {
  return ProcessingCompanion(
    recordId: Value<String>(recordId),
    stage: const Value<String>('prepare'),
    status: const Value<ProcessingJobStatus>(ProcessingJobStatus.queued),
    queuedAt: Value<DateTime>(queuedAt),
  );
}

void _seedVersion1(File file) {
  file.parent.createSync(recursive: true);
  final Database database = sqlite3.open(file.path);
  database.execute('PRAGMA user_version = 1');
  database.dispose();
}

Future<Set<String>> _columns(AppDatabase db, String table) async {
  final List<QueryRow> info = await db
      .customSelect('PRAGMA table_info("$table")')
      .get();
  return <String>{for (final QueryRow row in info) row.read<String>('name')};
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
