import 'package:drift/drift.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/processing.dart' as jobs;
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/job_retry.dart';
import '../domain/processing_repository.dart';
import 'processing_job_mapper.dart';
import 'processing_queue_queries.dart';

/// The queue's state changes: enqueue, claim, complete, fail, stage
/// progress, release and operator retry.
///
/// Each public method commits in one transaction (FE-STATE-07) and returns
/// a [Result], so a storage error surfaces as a [StorageFailure] rather
/// than a raw Drift exception.
final class ProcessingQueueWrites {
  /// Writes to [db]. [settings] supplies the concurrency cap. [queries]
  /// counts the running jobs.
  const ProcessingQueueWrites({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
    required this._settings,
    required this._queries,
  });

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final SettingsStore _settings;
  final ProcessingQueueQueries _queries;

  /// Queues captured records in [projectId] and [groupLabels] (empty for
  /// every group) that have no job yet, and returns how many it queued.
  Future<Result<int>> enqueuePending({
    String? projectId,
    List<String> groupLabels = const <String>[],
  }) {
    return runInTransaction(_db, () async {
      final String projectFilter = projectId == null
          ? ''
          : 'AND r.project_id = ? ';
      final List<QueryRow> rows = await _db
          .customSelect(
            "SELECT r.id, r.context_json FROM records r "
            "WHERE r.status IN ('CAPTURED', 'captured') "
            '$projectFilter'
            'AND NOT EXISTS ('
            'SELECT 1 FROM processing_jobs pj WHERE pj.record_id = r.id) '
            'ORDER BY r.captured_at, r.id',
            variables: <Variable<Object>>[
              if (projectId != null) Variable<String>(projectId),
            ],
            readsFrom: <ResultSetImplementation<Object?, Object?>>{
              _db.records,
              _db.processing,
            },
          )
          .get();
      var queued = 0;
      for (final QueryRow row in rows) {
        if (!_inGroups(row.read<String>('context_json'), groupLabels)) {
          continue;
        }
        await _insert(row.read<String>('id'));
        queued++;
      }
      return queued;
    });
  }

  /// Queues [recordId] once and returns the job id.
  Future<Result<String>> enqueue(String recordId) async {
    if (recordId.isEmpty) {
      return const FailureResult<String>(_noRecord);
    }
    return runInTransaction(_db, () async {
      final sqlite.ProcessingJobRow? existing =
          await (_db.select(_db.processing)
                ..where(
                  (sqlite.$ProcessingTable tbl) =>
                      tbl.recordId.equals(recordId),
                )
                ..orderBy(<OrderClauseGenerator<sqlite.$ProcessingTable>>[
                  (sqlite.$ProcessingTable tbl) =>
                      OrderingTerm.asc(tbl.queuedAt),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) {
        return existing.id;
      }
      return _insert(recordId);
    });
  }

  /// Claims the oldest ready job in scope for [lease].
  ///
  /// Expired leases are released first, inside the same transaction. The
  /// running jobs left then all hold a live lease, and while they number
  /// `SettingKeys.aiConcurrency` or more nothing is claimed. A job waiting
  /// out its backoff is not ready until its retry instant passes. With
  /// [unfinished], a job that has already completed that stage is passed
  /// over, as is any job in [skip].
  Future<Result<ProcessingJob?>> claim(
    Duration lease, {
    String? projectId,
    List<String> groupLabels = const <String>[],
    JobStage? unfinished,
    Set<String> skip = const <String>{},
  }) {
    return runInTransaction(_db, () async {
      final DateTime now = _clock.nowUtc();
      await _releaseExpired(now);
      final int cap = _settings.read(SettingKeys.aiConcurrency);
      final int running = await _queries.count(
        jobs.ProcessingJobStatus.running,
      );
      if (running >= cap) {
        return null;
      }
      final List<sqlite.ProcessingJobRow> candidates =
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
                ]))
              .get();
      for (final sqlite.ProcessingJobRow candidate in candidates) {
        if (skip.contains(candidate.id)) {
          continue;
        }
        if (unfinished != null && _reached(candidate.stage, unfinished)) {
          continue;
        }
        if (!await _inScope(candidate.recordId, projectId, groupLabels)) {
          continue;
        }
        final int changed =
            await (_db.update(_db.processing)..where(
                  (sqlite.$ProcessingTable tbl) =>
                      tbl.id.equals(candidate.id) &
                      tbl.status.equalsValue(jobs.ProcessingJobStatus.queued),
                ))
                .write(
                  _stamp(
                    candidate,
                    now,
                    sqlite.ProcessingCompanion(
                      status: const Value<jobs.ProcessingJobStatus>(
                        jobs.ProcessingJobStatus.running,
                      ),
                      startedAt: Value<DateTime>(now),
                      leaseExpiresAt: Value<DateTime>(now.add(lease)),
                    ),
                  ),
                );
        if (changed == 0) {
          return null;
        }
        return ProcessingJobMapper.toJob((await _one(candidate.id))!);
      }
      return null;
    });
  }

  /// Marks [jobId] completed and drops its lease.
  Future<Result<void>> complete(String jobId) {
    return runInTransaction(_db, () async {
      final sqlite.ProcessingJobRow? row = await _one(jobId);
      if (row == null) {
        return;
      }
      final DateTime now = _clock.nowUtc();
      await _write(
        row,
        now,
        sqlite.ProcessingCompanion(
          status: const Value<jobs.ProcessingJobStatus>(
            jobs.ProcessingJobStatus.completed,
          ),
          finishedAt: Value<DateTime>(now),
          leaseExpiresAt: const Value<DateTime?>(null),
          lastError: const Value<String?>(null),
        ),
      );
    });
  }

  /// Records [reason] on [jobId] and spends one attempt.
  ///
  /// A permanent failure, or the attempt that reaches
  /// `AppConstants.processing.maxAttempts`, stops the job. Otherwise it
  /// returns to the queue with its retry instant stored in `startedAt`, so
  /// [claim] withholds it until [JobRetry.backoffFor] has passed.
  Future<Result<void>> fail(
    String jobId,
    String reason, {
    required bool permanent,
  }) {
    return runInTransaction(_db, () async {
      final sqlite.ProcessingJobRow? row = await _one(jobId);
      if (row == null) {
        return;
      }
      final int attempts = row.attempts + 1;
      final bool stop =
          permanent || attempts >= AppConstants.processing.maxAttempts;
      final DateTime now = _clock.nowUtc();
      await _write(
        row,
        now,
        sqlite.ProcessingCompanion(
          status: Value<jobs.ProcessingJobStatus>(
            stop
                ? jobs.ProcessingJobStatus.failed
                : jobs.ProcessingJobStatus.queued,
          ),
          attempts: Value<int>(attempts),
          lastError: Value<String>(reason),
          startedAt: Value<DateTime?>(
            stop ? null : now.add(JobRetry.backoffFor(attempts)),
          ),
          finishedAt: Value<DateTime?>(stop ? now : null),
          leaseExpiresAt: const Value<DateTime?>(null),
        ),
      );
    });
  }

  /// Records [stage] as the last completed stage on [id].
  Future<Result<ProcessingJob>> markStage(String id, JobStage stage) {
    return runInTransaction(_db, () async {
      final sqlite.ProcessingJobRow row = await _existing(id);
      await _write(
        row,
        _clock.nowUtc(),
        sqlite.ProcessingCompanion(stage: Value<String>(stage.name)),
      );
      return ProcessingJobMapper.toJob((await _one(id))!);
    });
  }

  /// Returns [id] to the queue, keeping its completed stages.
  Future<Result<void>> release(String id) {
    return runInTransaction(_db, () async {
      final sqlite.ProcessingJobRow row = await _existing(id);
      await _write(
        row,
        _clock.nowUtc(),
        const sqlite.ProcessingCompanion(
          status: Value<jobs.ProcessingJobStatus>(
            jobs.ProcessingJobStatus.queued,
          ),
          leaseExpiresAt: Value<DateTime?>(null),
        ),
      );
    });
  }

  /// Returns a stopped [id] to the queue with a fresh attempt count.
  Future<Result<void>> retry(String id) {
    return runInTransaction(_db, () async {
      final sqlite.ProcessingJobRow row = await _existing(id);
      await _write(
        row,
        _clock.nowUtc(),
        const sqlite.ProcessingCompanion(
          status: Value<jobs.ProcessingJobStatus>(
            jobs.ProcessingJobStatus.queued,
          ),
          attempts: Value<int>(0),
          lastError: Value<String?>(null),
          startedAt: Value<DateTime?>(null),
          finishedAt: Value<DateTime?>(null),
          leaseExpiresAt: Value<DateTime?>(null),
        ),
      );
    });
  }

  Future<String> _insert(String recordId) async {
    final DateTime now = _clock.nowUtc();
    final Result<sqlite.ProcessingJobRow> written = await jobs
        .upsertProcessingJob(
          _db,
          row: ProcessingJobMapper.toCompanion(
            ProcessingJob(id: _ids.newId(), recordId: recordId, queuedAt: now),
            queuedAt: now,
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        );
    return written.fold(
      (Failure failure) => throw Failure.from(failure),
      (sqlite.ProcessingJobRow row) => row.id,
    );
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
      await _write(
        row,
        now,
        const sqlite.ProcessingCompanion(
          status: Value<jobs.ProcessingJobStatus>(
            jobs.ProcessingJobStatus.queued,
          ),
          leaseExpiresAt: Value<DateTime?>(null),
          startedAt: Value<DateTime?>(null),
        ),
      );
    }
  }

  /// Whether a job whose last completed stage is [stage] has done [target].
  bool _reached(String stage, JobStage target) {
    final int done = JobStage.values.indexWhere(
      (JobStage value) => value.name == stage,
    );
    return done >= JobStage.values.indexOf(target);
  }

  Future<bool> _inScope(
    String recordId,
    String? projectId,
    List<String> groupLabels,
  ) async {
    if (projectId == null && groupLabels.isEmpty) {
      return true;
    }
    final sqlite.RecordRow? record =
        await (_db.select(_db.records)
              ..where((sqlite.$RecordsTable tbl) => tbl.id.equals(recordId)))
            .getSingleOrNull();
    if (record == null) {
      return false;
    }
    if (projectId != null && record.projectId != projectId) {
      return false;
    }
    return _inGroups(record.contextJson, groupLabels);
  }

  bool _inGroups(String contextJson, List<String> groupLabels) {
    return groupLabels.isEmpty ||
        groupLabels.contains(ProcessingQueueQueries.contextLabel(contextJson));
  }

  Future<sqlite.ProcessingJobRow?> _one(String id) {
    return (_db.select(_db.processing)
          ..where((sqlite.$ProcessingTable tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<sqlite.ProcessingJobRow> _existing(String id) async {
    final sqlite.ProcessingJobRow? row = await _one(id);
    if (row == null) {
      throw _missingFailure;
    }
    return row;
  }

  Future<void> _write(
    sqlite.ProcessingJobRow row,
    DateTime now,
    sqlite.ProcessingCompanion changes,
  ) {
    return (_db.update(_db.processing)
          ..where((sqlite.$ProcessingTable tbl) => tbl.id.equals(row.id)))
        .write(_stamp(row, now, changes));
  }

  /// [changes] plus the sync stamp every job write carries.
  sqlite.ProcessingCompanion _stamp(
    sqlite.ProcessingJobRow row,
    DateTime now,
    sqlite.ProcessingCompanion changes,
  ) {
    return changes.copyWith(
      updatedAt: Value<DateTime>(now),
      updatedByDevice: Value<String>(_deviceId),
      rev: Value<int>(row.rev + 1),
    );
  }
}

const ValidationFailure _noRecord = ValidationFailure(
  message: 'A job needs a record.',
  recoveryAction: 'Open a record and queue it again.',
);

const StorageFailure _missingFailure = StorageFailure(
  message: 'That job is no longer on this device.',
  recoveryAction: 'Refresh the queue and try again.',
);
