import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/tables/processing.dart' as jobs;
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/job_retry.dart';
import '../domain/processing_repository.dart';

/// Drift-backed [ProcessingRepository].
final class ProcessingRepositoryImpl implements ProcessingRepository {
  /// Opens against [db]. [settings] supplies the concurrency cap.
  ProcessingRepositoryImpl({
    required sqlite.AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    required this._settings,
  }) : _db = db,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids,
       _dao = _JobDao(db, clock: clock, deviceId: deviceId, ids: ids);

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final SettingsStore _settings;
  final _JobDao _dao;

  @override
  Stream<List<ProcessingJob>> watchAll() {
    final SimpleSelectStatement<
      sqlite.$ProcessingTable,
      sqlite.ProcessingJobRow
    >
    query = _db.select(_db.processing)
      ..orderBy(<OrderClauseGenerator<sqlite.$ProcessingTable>>[
        (sqlite.$ProcessingTable tbl) => OrderingTerm.asc(tbl.queuedAt),
      ]);
    return query.watch().asyncMap((List<sqlite.ProcessingJobRow> rows) async {
      final Set<String> gone = await _tombstones();
      return <ProcessingJob>[
        for (final sqlite.ProcessingJobRow row in rows)
          if (!gone.contains(row.id)) _toJob(row),
      ];
    });
  }

  @override
  Stream<QueueSnapshot> watchQueue() {
    return _db.select(_db.processing).watch().asyncMap((
      List<sqlite.ProcessingJobRow> _,
    ) async {
      return _snapshot();
    });
  }

  @override
  Future<Result<ProcessingJob?>> byId(String id) async {
    try {
      if ((await _tombstones()).contains(id)) {
        return const Success<ProcessingJob?>(null);
      }
      final sqlite.ProcessingJobRow? row = await _one(id);
      return Success<ProcessingJob?>(row == null ? null : _toJob(row));
    } on Object catch (error) {
      return FailureResult<ProcessingJob?>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<ProcessingJob>> save(ProcessingJob job) async {
    if (job.recordId.isEmpty) {
      return const FailureResult<ProcessingJob>(
        ValidationFailure(
          message: 'A job needs a record.',
          recoveryAction: 'Open a record and queue it again.',
        ),
      );
    }
    final String id = job.id.isEmpty ? _ids.newId() : job.id;
    final Result<sqlite.ProcessingJobRow> written = await jobs
        .upsertProcessingJob(
          _db,
          row: _companion(job.copyWith(id: id)),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        );
    return written.map(_toJob);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) {
    return _dao.softDelete(id, reason: reason);
  }

  @override
  Future<String> enqueue(String recordId) async {
    if (recordId.isEmpty) {
      throw const ValidationFailure(
        message: 'A job needs a record.',
        recoveryAction: 'Open a record and queue it again.',
      );
    }
    final sqlite.ProcessingJobRow? existing =
        await (_db.select(_db.processing)
              ..where(
                (sqlite.$ProcessingTable tbl) =>
                    tbl.recordId.equals(recordId) &
                    tbl.status
                        .equalsValue(jobs.ProcessingJobStatus.completed)
                        .not(),
              )
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) {
      return existing.id;
    }
    final Result<ProcessingJob> saved = await save(
      ProcessingJob(
        id: _ids.newId(),
        recordId: recordId,
        queuedAt: _clock.nowUtc(),
      ),
    );
    return saved.fold((Failure failure) => throw failure, (ProcessingJob job) {
      return job.id;
    });
  }

  @override
  Future<ProcessingJob?> claim(Duration lease) async {
    final Result<ProcessingJob?> result = await runInTransaction(_db, () async {
      final DateTime now = _clock.nowUtc();
      await _releaseExpired(now);
      final int cap = _settings.read(SettingKeys.aiConcurrency);
      final int running = await _count(jobs.ProcessingJobStatus.running);
      if (running >= cap) {
        return null;
      }
      final sqlite.ProcessingJobRow? next =
          await (_db.select(_db.processing)
                ..where(
                  (sqlite.$ProcessingTable tbl) =>
                      tbl.status.equalsValue(jobs.ProcessingJobStatus.queued) &
                      (tbl.startedAt.isNull() |
                          tbl.startedAt.isSmallerOrEqualValue(now)),
                )
                ..orderBy(<OrderClauseGenerator<sqlite.$ProcessingTable>>[
                  (sqlite.$ProcessingTable tbl) =>
                      OrderingTerm.asc(tbl.queuedAt),
                  (sqlite.$ProcessingTable tbl) => OrderingTerm.asc(tbl.id),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (next == null) {
        return null;
      }
      final int changed =
          await (_db.update(_db.processing)..where(
                (sqlite.$ProcessingTable tbl) =>
                    tbl.id.equals(next.id) &
                    tbl.status.equalsValue(jobs.ProcessingJobStatus.queued),
              ))
              .write(
                sqlite.ProcessingCompanion(
                  status: const Value<jobs.ProcessingJobStatus>(
                    jobs.ProcessingJobStatus.running,
                  ),
                  startedAt: Value<DateTime>(now),
                  leaseExpiresAt: Value<DateTime>(now.add(lease)),
                  updatedAt: Value<DateTime>(now),
                  updatedByDevice: Value<String>(_deviceId),
                  rev: Value<int>(next.rev + 1),
                ),
              );
      if (changed == 0) {
        return null;
      }
      final sqlite.ProcessingJobRow row =
          await (_db.select(
                _db.processing,
              )..where((sqlite.$ProcessingTable tbl) => tbl.id.equals(next.id)))
              .getSingle();
      return _toJob(row);
    });
    return result.fold((Failure failure) => throw failure, (
      ProcessingJob? job,
    ) {
      return job;
    });
  }

  @override
  Future<void> complete(String jobId) async {
    final sqlite.ProcessingJobRow? row = await _one(jobId);
    if (row == null) {
      return;
    }
    final DateTime now = _clock.nowUtc();
    await (_db.update(
      _db.processing,
    )..where((sqlite.$ProcessingTable tbl) => tbl.id.equals(jobId))).write(
      sqlite.ProcessingCompanion(
        status: const Value<jobs.ProcessingJobStatus>(
          jobs.ProcessingJobStatus.completed,
        ),
        finishedAt: Value<DateTime>(now),
        leaseExpiresAt: const Value<DateTime?>(null),
        updatedAt: Value<DateTime>(now),
        updatedByDevice: Value<String>(_deviceId),
        rev: Value<int>(row.rev + 1),
      ),
    );
  }

  @override
  Future<void> fail(
    String jobId,
    String reason, {
    required bool permanent,
  }) async {
    final sqlite.ProcessingJobRow? row = await _one(jobId);
    if (row == null) {
      return;
    }
    final int attempts = row.attempts + 1;
    final bool stop =
        permanent || attempts >= AppConstants.processing.maxAttempts;
    final DateTime now = _clock.nowUtc();
    final DateTime? retryAt = stop
        ? null
        : now.add(JobRetry.backoffFor(attempts));
    await (_db.update(
      _db.processing,
    )..where((sqlite.$ProcessingTable tbl) => tbl.id.equals(jobId))).write(
      sqlite.ProcessingCompanion(
        status: Value<jobs.ProcessingJobStatus>(
          stop
              ? jobs.ProcessingJobStatus.failed
              : jobs.ProcessingJobStatus.queued,
        ),
        attempts: Value<int>(attempts),
        lastError: Value<String>(reason),
        startedAt: Value<DateTime?>(retryAt),
        finishedAt: Value<DateTime?>(stop ? now : null),
        leaseExpiresAt: const Value<DateTime?>(null),
        updatedAt: Value<DateTime>(now),
        updatedByDevice: Value<String>(_deviceId),
        rev: Value<int>(row.rev + 1),
      ),
    );
  }

  @override
  Future<Result<ProcessingJob>> markStage(String id, JobStage stage) async {
    final sqlite.ProcessingJobRow? row = await _one(id);
    if (row == null) {
      return const FailureResult<ProcessingJob>(_missing);
    }
    final DateTime now = _clock.nowUtc();
    await (_db.update(
      _db.processing,
    )..where((sqlite.$ProcessingTable tbl) => tbl.id.equals(id))).write(
      sqlite.ProcessingCompanion(
        stage: Value<String>(stage.name),
        updatedAt: Value<DateTime>(now),
        updatedByDevice: Value<String>(_deviceId),
        rev: Value<int>(row.rev + 1),
      ),
    );
    final sqlite.ProcessingJobRow next = (await _one(id))!;
    return Success<ProcessingJob>(_toJob(next));
  }

  @override
  Future<Result<void>> release(String id) async {
    final sqlite.ProcessingJobRow? row = await _one(id);
    if (row == null) {
      return const FailureResult<void>(_missing);
    }
    final DateTime now = _clock.nowUtc();
    await (_db.update(
      _db.processing,
    )..where((sqlite.$ProcessingTable tbl) => tbl.id.equals(id))).write(
      sqlite.ProcessingCompanion(
        status: const Value<jobs.ProcessingJobStatus>(
          jobs.ProcessingJobStatus.queued,
        ),
        leaseExpiresAt: const Value<DateTime?>(null),
        updatedAt: Value<DateTime>(now),
        updatedByDevice: Value<String>(_deviceId),
        rev: Value<int>(row.rev + 1),
      ),
    );
    return const Success<void>(null);
  }

  @override
  Future<Result<({int requests, int images})>> usageOn(DateTime day) async {
    try {
      final DateTime start = DateTime.utc(day.year, day.month, day.day);
      final DateTime end = start.add(const Duration(days: 1));
      final List<sqlite.ProcessingResult> rows =
          await (_db.select(_db.processingResults)..where(
                (sqlite.$ProcessingResultsTable tbl) =>
                    tbl.createdAt.isBiggerOrEqualValue(start) &
                    tbl.createdAt.isSmallerThanValue(end),
              ))
              .get();
      var images = 0;
      for (final sqlite.ProcessingResult row in rows) {
        images += _imageCount(row.requestSummary);
      }
      return Success<({int requests, int images})>((
        requests: rows.length,
        images: images,
      ));
    } on Object catch (error) {
      return FailureResult<({int requests, int images})>(
        storageFailureFrom(error),
      );
    }
  }

  Future<void> _releaseExpired(DateTime now) async {
    final List<sqlite.ProcessingJobRow> expired =
        await (_db.select(_db.processing)..where(
              (sqlite.$ProcessingTable tbl) =>
                  tbl.status.equalsValue(jobs.ProcessingJobStatus.running) &
                  (tbl.leaseExpiresAt.isNull() |
                      tbl.leaseExpiresAt.isSmallerThanValue(now)),
            ))
            .get();
    for (final sqlite.ProcessingJobRow row in expired) {
      await (_db.update(
        _db.processing,
      )..where((sqlite.$ProcessingTable tbl) => tbl.id.equals(row.id))).write(
        sqlite.ProcessingCompanion(
          status: const Value<jobs.ProcessingJobStatus>(
            jobs.ProcessingJobStatus.queued,
          ),
          leaseExpiresAt: const Value<DateTime?>(null),
          startedAt: const Value<DateTime?>(null),
          updatedAt: Value<DateTime>(now),
          updatedByDevice: Value<String>(_deviceId),
          rev: Value<int>(row.rev + 1),
        ),
      );
    }
  }

  Future<int> _count(jobs.ProcessingJobStatus status) async {
    final QueryRow row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM processing_jobs WHERE status = ?',
          variables: <Variable<String>>[Variable<String>(status.name)],
        )
        .getSingle();
    return row.read<int>('c');
  }

  Future<QueueSnapshot> _snapshot() async {
    final int queued = await _count(jobs.ProcessingJobStatus.queued);
    final int running = await _count(jobs.ProcessingJobStatus.running);
    final int failed = await _count(jobs.ProcessingJobStatus.failed);
    final int unprocessed = await _unprocessed();
    final List<sqlite.ProcessingJobRow> failedRows =
        await (_db.select(_db.processing)
              ..where(
                (sqlite.$ProcessingTable tbl) =>
                    tbl.status.equalsValue(jobs.ProcessingJobStatus.failed),
              )
              ..orderBy(<OrderClauseGenerator<sqlite.$ProcessingTable>>[
                (sqlite.$ProcessingTable tbl) => OrderingTerm.asc(tbl.queuedAt),
              ]))
            .get();
    return (
      unprocessed: unprocessed,
      queued: queued + running,
      failed: failed,
      groups: await _groups(),
      failures: <ProcessingJob>[
        for (final sqlite.ProcessingJobRow row in failedRows) _toJob(row),
      ],
    );
  }

  Future<int> _unprocessed() async {
    final QueryRow row = await _db
        .customSelect(
          "SELECT COUNT(*) AS c FROM records "
          "WHERE status IN ('CAPTURED', 'captured') "
          "AND NOT EXISTS ("
          "SELECT 1 FROM processing_jobs "
          "WHERE processing_jobs.record_id = records.id "
          "AND processing_jobs.status != 'failed')",
        )
        .getSingle();
    return row.read<int>('c');
  }

  Future<List<QueueGroup>> _groups() async {
    final List<QueryRow> rows = await _db
        .customSelect(
          "SELECT context_json AS label, COUNT(*) AS n FROM records "
          "WHERE status IN ('CAPTURED', 'captured', 'queued') "
          "GROUP BY context_json",
        )
        .get();
    final Map<String, int> grouped = <String, int>{};
    for (final QueryRow row in rows) {
      final String label = _contextLabel(row.read<String>('label'));
      grouped.update(
        label,
        (int count) => count + row.read<int>('n'),
        ifAbsent: () => row.read<int>('n'),
      );
    }
    return <QueueGroup>[
      for (final MapEntry<String, int> entry in grouped.entries)
        (label: entry.key, records: entry.value),
    ];
  }

  Future<sqlite.ProcessingJobRow?> _one(String id) {
    return (_db.select(_db.processing)
          ..where((sqlite.$ProcessingTable tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Set<String>> _tombstones() async {
    final List<sqlite.Tombstone> rows =
        await (_db.select(_db.tombstones)..where(
              (sqlite.$TombstonesTable tbl) =>
                  tbl.entityType.equals('processing_jobs'),
            ))
            .get();
    return <String>{for (final sqlite.Tombstone row in rows) row.entityId};
  }

  sqlite.ProcessingCompanion _companion(ProcessingJob job) {
    return sqlite.ProcessingCompanion(
      id: Value<String>(job.id),
      recordId: Value<String>(job.recordId),
      stage: Value<String>(job.stage),
      status: Value<jobs.ProcessingJobStatus>(_status(job.status)),
      attempts: Value<int>(job.attemptCount),
      lastError: Value<String?>(job.lastError),
      queuedAt: Value<DateTime>(job.queuedAt ?? _clock.nowUtc()),
      startedAt: Value<DateTime?>(job.startedAt),
      finishedAt: Value<DateTime?>(job.finishedAt),
      provider: Value<String?>(job.provider),
      model: Value<String?>(job.model),
      leaseExpiresAt: Value<DateTime?>(job.leaseExpiresAt),
      skipReason: Value<String?>(job.skipReason),
      rejections: Value<String?>(
        job.rejections.isEmpty ? null : jsonEncode(job.rejections),
      ),
    );
  }
}

/// The job store. Defaults to an empty stand-in so suites never open Drift.
final Provider<ProcessingRepository> processingRepositoryProvider =
    Provider<ProcessingRepository>((Ref _) => _EmptyProcessingRepository());

final class _EmptyProcessingRepository implements ProcessingRepository {
  @override
  Stream<List<ProcessingJob>> watchAll() {
    return Stream<List<ProcessingJob>>.value(const <ProcessingJob>[]);
  }

  @override
  Stream<QueueSnapshot> watchQueue() {
    return Stream<QueueSnapshot>.value(emptyQueueSnapshot);
  }

  @override
  Future<Result<ProcessingJob?>> byId(String id) async {
    return const Success<ProcessingJob?>(null);
  }

  @override
  Future<Result<ProcessingJob>> save(ProcessingJob job) async {
    return const FailureResult<ProcessingJob>(_missing);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    return const FailureResult<void>(_missing);
  }

  @override
  Future<String> enqueue(String recordId) async {
    throw const StorageFailure(
      message: 'That job is no longer on this device.',
      recoveryAction: 'Refresh the queue and try again.',
    );
  }

  @override
  Future<ProcessingJob?> claim(Duration lease) async => null;

  @override
  Future<void> complete(String jobId) async {}

  @override
  Future<void> fail(
    String jobId,
    String reason, {
    required bool permanent,
  }) async {}

  @override
  Future<Result<ProcessingJob>> markStage(String id, JobStage stage) async {
    return const FailureResult<ProcessingJob>(_missing);
  }

  @override
  Future<Result<void>> release(String id) async {
    return const FailureResult<void>(_missing);
  }

  @override
  Future<Result<({int requests, int images})>> usageOn(DateTime day) async {
    return const Success<({int requests, int images})>((
      requests: 0,
      images: 0,
    ));
  }
}

final class _JobDao extends BaseDao<jobs.Processing, sqlite.ProcessingJobRow> {
  _JobDao(
    sqlite.AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.processing);
}

ProcessingJob _toJob(sqlite.ProcessingJobRow row) {
  return ProcessingJob(
    id: row.id,
    recordId: row.recordId,
    stage: row.stage,
    attemptCount: row.attempts,
    status: _jobStatus(row.status),
    lastError: row.lastError,
    leaseExpiresAt: row.leaseExpiresAt,
    permanent: row.status == jobs.ProcessingJobStatus.failed,
    skipReason: row.skipReason,
    rejections: _rejections(row.rejections),
    provider: row.provider,
    model: row.model,
    queuedAt: row.queuedAt,
    startedAt: row.startedAt,
    finishedAt: row.finishedAt,
  );
}

jobs.ProcessingJobStatus _status(JobStatus status) {
  return switch (status) {
    JobStatus.queued => jobs.ProcessingJobStatus.queued,
    JobStatus.running => jobs.ProcessingJobStatus.running,
    JobStatus.completed => jobs.ProcessingJobStatus.completed,
    JobStatus.failed => jobs.ProcessingJobStatus.failed,
  };
}

JobStatus _jobStatus(jobs.ProcessingJobStatus status) {
  return switch (status) {
    jobs.ProcessingJobStatus.queued => JobStatus.queued,
    jobs.ProcessingJobStatus.running => JobStatus.running,
    jobs.ProcessingJobStatus.completed => JobStatus.completed,
    jobs.ProcessingJobStatus.failed => JobStatus.failed,
  };
}

List<String> _rejections(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const <String>[];
  }
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is List) {
      return <String>[
        for (final Object? item in decoded)
          if (item is String) item,
      ];
    }
  } on FormatException {
    return const <String>[];
  }
  return const <String>[];
}

int _imageCount(String summary) {
  try {
    final Object? decoded = jsonDecode(summary);
    if (decoded is Map && decoded['images'] is List) {
      return (decoded['images'] as List).length;
    }
    if (decoded is Map && decoded['imageCount'] is int) {
      return decoded['imageCount'] as int;
    }
  } on FormatException {
    return 0;
  }
  return 0;
}

String _contextLabel(String raw) {
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return 'Unassigned';
    }
    final List<String> parts = <String>[];
    for (final String key in const <String>[
      'district',
      'facility',
      'department',
      'room',
    ]) {
      final Object? value = decoded[key];
      if (value is String && value.isNotEmpty) {
        parts.add(value);
      }
    }
    if (parts.isEmpty) {
      return 'Unassigned';
    }
    return parts.join(' / ');
  } on FormatException {
    return 'Unassigned';
  }
}

const StorageFailure _missing = StorageFailure(
  message: 'That job is no longer on this device.',
  recoveryAction: 'Refresh the queue and try again.',
);
