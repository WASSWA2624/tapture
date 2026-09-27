import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/processing.dart' as jobs;
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/job_retry.dart';
import '../domain/processing_repository.dart';
import 'processing_job_mapper.dart';
import 'processing_queue_queries.dart';

/// The queue's state changes: enqueue, claim, complete, fail, stage
/// progress, release, operator retry and re-processing a record.
///
/// Each public method commits in one transaction (FE-STATE-07) and returns
/// a [Result], so a storage error surfaces as a [StorageFailure] rather
/// than a raw Drift exception.
///
/// A finished run is written to the record's history: one audit row on
/// entity `records` with field key `processing`, new value
/// `completed` or `failed`, and a JSON reason naming the job, stage and
/// provider, never a value (task 014 D10). Record status moves go through
/// `writeRecordStatus`; processing is an exempt caller of the record
/// lifecycle, so only the moves named here are made.
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
            'SELECT r.id, r.context_json FROM records r '
            'WHERE r.status = ? '
            '$projectFilter'
            'AND NOT EXISTS ('
            'SELECT 1 FROM processing_jobs pj WHERE pj.record_id = r.id) '
            'ORDER BY r.captured_at, r.id',
            variables: <Variable<Object>>[
              Variable<String>(RecordStatus.captured.stored),
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

  /// Queues [recordId] to be processed again from the first stage and
  /// returns the job id.
  ///
  /// The record's job is reset (stage cleared, queued, attempts 0; lease,
  /// error, timestamps, provider and rejections cleared), or a job is
  /// inserted when it has none. A record whose status may move to queued
  /// moves there through `writeRecordStatus`; one already queued keeps its
  /// status. Any other status (processing, archived, deleted), or a job a
  /// runner holds under a live lease, fails with a [ValidationFailure] and
  /// writes nothing.
  Future<Result<String>> requeue(String recordId) async {
    if (recordId.isEmpty) {
      return const FailureResult<String>(_noRecord);
    }
    final Result<Result<String>> outcome = await runInTransaction(
      _db,
      () async {
        final sqlite.RecordRow? record =
            await (_db.select(
                  _db.records,
                )..where((sqlite.$RecordsTable tbl) => tbl.id.equals(recordId)))
                .getSingleOrNull();
        if (record == null) {
          return const FailureResult<String>(_recordGone);
        }
        final RecordStatus? status = RecordStatus.fromStored(record.status);
        final bool moves = status != null && _requeueFrom.contains(status);
        if (!moves && status != RecordStatus.queued) {
          return FailureResult<String>(_notRequeueable(status));
        }
        final DateTime now = _clock.nowUtc();
        final sqlite.ProcessingJobRow? job = await _jobFor(recordId);
        if (job != null &&
            job.status == jobs.ProcessingJobStatus.running &&
            (job.leaseExpiresAt?.isAfter(now) ?? false)) {
          return const FailureResult<String>(_runningNow);
        }
        final String jobId;
        if (job == null) {
          jobId = await _insert(recordId);
        } else {
          await _write(
            job,
            now,
            sqlite.ProcessingCompanion(
              stage: const Value<String>(''),
              status: const Value<jobs.ProcessingJobStatus>(
                jobs.ProcessingJobStatus.queued,
              ),
              attempts: const Value<int>(0),
              lastError: const Value<String?>(null),
              queuedAt: Value<DateTime>(now),
              startedAt: const Value<DateTime?>(null),
              finishedAt: const Value<DateTime?>(null),
              leaseExpiresAt: const Value<DateTime?>(null),
              provider: const Value<String?>(null),
              model: const Value<String?>(null),
              skipReason: const Value<String?>(null),
              rejections: const Value<String?>(null),
            ),
          );
          jobId = job.id;
        }
        if (moves) {
          await writeRecordStatus(
            _db,
            recordId: recordId,
            status: RecordStatus.queued.stored,
            previousStatus: record.status,
            clock: _clock,
            deviceId: _deviceId,
            reason: _moveReason(_requeueAction, jobId),
          );
        }
        return Success<String>(jobId);
      },
    );
    return outcome.fold(
      FailureResult<String>.new,
      (Result<String> inner) => inner,
    );
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

  /// Marks [jobId] completed, drops its lease and writes the run to the
  /// record's history.
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
      await _auditRun(row, _runCompleted);
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
      if (!stop) {
        return;
      }
      // A run that stops for good is history, and a record still waiting on
      // it is failed rather than left looking queued.
      await _auditRun(row, _runFailed, attempts: attempts);
      await _moveRecord(
        row,
        from: _failFrom,
        to: RecordStatus.failed,
        action: _runFailed,
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

  /// Returns a stopped [id] to the queue with a fresh attempt count. A
  /// record the stopped run left failed is queued again with it.
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
      await _moveRecord(
        row,
        from: const <RecordStatus>{RecordStatus.failed},
        to: RecordStatus.queued,
        action: _retryAction,
      );
    });
  }

  /// The oldest live job of [recordId], as [enqueue] picks it, or null.
  Future<sqlite.ProcessingJobRow?> _jobFor(String recordId) async {
    final List<sqlite.ProcessingJobRow> rows =
        await (_db.select(_db.processing)
              ..where(
                (sqlite.$ProcessingTable tbl) => tbl.recordId.equals(recordId),
              )
              ..orderBy(<OrderClauseGenerator<sqlite.$ProcessingTable>>[
                (sqlite.$ProcessingTable tbl) => OrderingTerm.asc(tbl.queuedAt),
                (sqlite.$ProcessingTable tbl) => OrderingTerm.asc(tbl.id),
              ]))
            .get();
    if (rows.isEmpty) {
      return null;
    }
    final List<sqlite.Tombstone> tombs =
        await (_db.select(_db.tombstones)..where(
              (sqlite.$TombstonesTable tbl) =>
                  tbl.entityType.equals(_db.processing.actualTableName) &
                  tbl.entityId.isIn(<String>[
                    for (final sqlite.ProcessingJobRow row in rows) row.id,
                  ]),
            ))
            .get();
    final Set<String> gone = <String>{
      for (final sqlite.Tombstone tomb in tombs) tomb.entityId,
    };
    for (final sqlite.ProcessingJobRow row in rows) {
      if (!gone.contains(row.id)) {
        return row;
      }
    }
    return null;
  }

  /// Appends the finished run of [job] to its record's history.
  Future<void> _auditRun(
    sqlite.ProcessingJobRow job,
    String outcome, {
    int? attempts,
  }) {
    final String? provider = job.provider;
    final String? model = job.model;
    return appendAudit(
      _db,
      entityType: _db.records.actualTableName,
      entityId: job.recordId,
      action: AuditAction.updated,
      fieldKey: _processingAuditKey,
      newValue: outcome,
      reason: jsonEncode(<String, Object>{
        'job': job.id,
        if (job.stage.isNotEmpty) 'stage': job.stage,
        if (provider != null && provider.isNotEmpty) 'provider': provider,
        if (model != null && model.isNotEmpty) 'model': model,
        'attempts': ?attempts,
      }),
      clock: _clock,
      device: _deviceId,
    );
  }

  /// Moves [job]'s record to [to] when its status is one of [from]; a record
  /// in any other status, or no longer here, is left alone.
  Future<void> _moveRecord(
    sqlite.ProcessingJobRow job, {
    required Set<RecordStatus> from,
    required RecordStatus to,
    required String action,
  }) async {
    final sqlite.RecordRow? record =
        await (_db.select(
              _db.records,
            )..where((sqlite.$RecordsTable tbl) => tbl.id.equals(job.recordId)))
            .getSingleOrNull();
    if (record == null) {
      return;
    }
    final RecordStatus? status = RecordStatus.fromStored(record.status);
    if (status == null || !from.contains(status)) {
      return;
    }
    await writeRecordStatus(
      _db,
      recordId: record.id,
      status: to.stored,
      previousStatus: record.status,
      clock: _clock,
      deviceId: _deviceId,
      reason: _moveReason(action, job.id),
    );
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

/// Audit `field_key` of a finished processing run, on entity `records`.
const String _processingAuditKey = 'processing';

/// New value of the audit row a completed run writes.
const String _runCompleted = 'completed';

/// New value of the audit row a run that stopped for good writes, and the
/// action named when it moves its record to failed.
const String _runFailed = 'failed';

/// Action named when a record is queued to be processed from the first
/// stage again.
const String _requeueAction = 'requeue';

/// Action named when an operator retry queues a failed record again.
const String _retryAction = 'retry';

/// Statuses a record may leave for queued when it is processed again.
///
/// Inlined from the records lifecycle (`RecordLifecycle` in
/// features/records/domain, task 014 D4), which processing cannot import:
/// every status allowed to move to queued except processing, archived and
/// deleted, which a re-process must not touch.
const Set<RecordStatus> _requeueFrom = <RecordStatus>{
  RecordStatus.draft,
  RecordStatus.captured,
  RecordStatus.extracted,
  RecordStatus.needsReview,
  RecordStatus.approved,
  RecordStatus.failed,
};

/// Statuses a record still waiting on its run leaves for failed when the
/// run stops for good.
const Set<RecordStatus> _failFrom = <RecordStatus>{
  RecordStatus.captured,
  RecordStatus.queued,
  RecordStatus.processing,
};

const StorageFailure _recordGone = StorageFailure(
  message: 'That record is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

const ValidationFailure _runningNow = ValidationFailure(
  message: 'This record is being processed now.',
  recoveryAction: 'Wait for the run to finish, then process it again.',
);

/// Why a record in [status] cannot be queued again.
ValidationFailure _notRequeueable(RecordStatus? status) {
  return switch (status) {
    RecordStatus.archived => const ValidationFailure(
      message: 'An archived record cannot be processed again.',
      recoveryAction: 'Restore the record first, then process it again.',
    ),
    RecordStatus.deleted => const ValidationFailure(
      message: 'A deleted record cannot be processed again.',
      recoveryAction: 'Restore the record first, then process it again.',
    ),
    RecordStatus.processing => _runningNow,
    _ => const ValidationFailure(
      message: 'This record cannot be processed again.',
      recoveryAction: 'Refresh the list and try again.',
    ),
  };
}

/// Audit reason of a status move processing makes: what moved it and the
/// job, as JSON like the other processing audit reasons.
String _moveReason(String action, String jobId) {
  return jsonEncode(<String, String>{'action': action, 'job': jobId});
}

const StorageFailure _missingFailure = StorageFailure(
  message: 'That job is no longer on this device.',
  recoveryAction: 'Refresh the queue and try again.',
);
