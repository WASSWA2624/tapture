import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/tables/processing.dart' as jobs;
import 'package:tapture/core/db/tables/record_fields.dart';
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
  Stream<QueueSnapshot> watchQueue({String? projectId}) {
    return _db
        .customSelect(
          'SELECT 1',
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.processing,
            _db.processingResults,
            _db.records,
          },
        )
        .watch()
        .asyncMap((_) async {
          return _snapshot(projectId: projectId);
        });
  }

  @override
  Future<Result<int>> enqueuePending({String? projectId, String? groupLabel}) {
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
        if (groupLabel != null &&
            _contextLabel(row.read<String>('context_json')) != groupLabel) {
          continue;
        }
        final Result<ProcessingJob> saved = await save(
          ProcessingJob(
            id: _ids.newId(),
            recordId: row.read<String>('id'),
            queuedAt: _clock.nowUtc(),
          ),
        );
        saved.fold(
          (Failure failure) => throw Failure.from(failure),
          (_) => queued++,
        );
      }
      return queued;
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
  Future<Result<String>> enqueue(String recordId) async {
    if (recordId.isEmpty) {
      return const FailureResult<String>(
        ValidationFailure(
          message: 'A job needs a record.',
          recoveryAction: 'Open a record and queue it again.',
        ),
      );
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
      final Result<ProcessingJob> saved = await save(
        ProcessingJob(
          id: _ids.newId(),
          recordId: recordId,
          queuedAt: _clock.nowUtc(),
        ),
      );
      return saved.fold(
        (Failure failure) => throw Failure.from(failure),
        (ProcessingJob job) => job.id,
      );
    });
  }

  @override
  Future<Result<ProcessingJob?>> claim(
    Duration lease, {
    String? projectId,
    String? groupLabel,
  }) async {
    return runInTransaction(_db, () async {
      final DateTime now = _clock.nowUtc();
      await _releaseExpired(now);
      final int cap = _settings.read(SettingKeys.aiConcurrency);
      final int running = await _count(jobs.ProcessingJobStatus.running);
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
      sqlite.ProcessingJobRow? next;
      for (final sqlite.ProcessingJobRow candidate in candidates) {
        if (projectId == null && groupLabel == null) {
          next = candidate;
          break;
        }
        final sqlite.RecordRow? record =
            await (_db.select(_db.records)..where(
                  (sqlite.$RecordsTable tbl) =>
                      tbl.id.equals(candidate.recordId),
                ))
                .getSingleOrNull();
        if (record == null ||
            (projectId != null && record.projectId != projectId) ||
            (groupLabel != null &&
                _contextLabel(record.contextJson) != groupLabel)) {
          continue;
        }
        next = candidate;
        break;
      }
      final sqlite.ProcessingJobRow? candidate = next;
      if (candidate == null) {
        return null;
      }
      final int changed =
          await (_db.update(_db.processing)..where(
                (sqlite.$ProcessingTable tbl) =>
                    tbl.id.equals(candidate.id) &
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
                  rev: Value<int>(candidate.rev + 1),
                ),
              );
      if (changed == 0) {
        return null;
      }
      final sqlite.ProcessingJobRow row =
          await (_db.select(_db.processing)..where(
                (sqlite.$ProcessingTable tbl) => tbl.id.equals(candidate.id),
              ))
              .getSingle();
      return _toJob(row);
    });
  }

  @override
  Future<Result<void>> complete(String jobId) {
    return runInTransaction(_db, () async {
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
          lastError: const Value<String?>(null),
          updatedAt: Value<DateTime>(now),
          updatedByDevice: Value<String>(_deviceId),
          rev: Value<int>(row.rev + 1),
        ),
      );
    });
  }

  @override
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
    });
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
  Future<Result<void>> retry(String id) async {
    return runInTransaction(_db, () async {
      final sqlite.ProcessingJobRow? row = await _one(id);
      if (row == null) {
        throw const StorageFailure(
          message: 'That job is no longer on this device.',
          recoveryAction: 'Refresh the queue and try again.',
        );
      }
      final DateTime now = _clock.nowUtc();
      await (_db.update(
        _db.processing,
      )..where((sqlite.$ProcessingTable tbl) => tbl.id.equals(id))).write(
        sqlite.ProcessingCompanion(
          status: const Value<jobs.ProcessingJobStatus>(
            jobs.ProcessingJobStatus.queued,
          ),
          attempts: const Value<int>(0),
          lastError: const Value<String?>(null),
          startedAt: const Value<DateTime?>(null),
          finishedAt: const Value<DateTime?>(null),
          leaseExpiresAt: const Value<DateTime?>(null),
          updatedAt: Value<DateTime>(now),
          updatedByDevice: Value<String>(_deviceId),
          rev: Value<int>(row.rev + 1),
        ),
      );
    });
  }

  @override
  Future<Result<({int requests, int images})>> usageOn(
    DateTime day, {
    String? projectId,
  }) async {
    try {
      return Success<({int requests, int images})>(
        await _usageOn(day, projectId: projectId),
      );
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

  Future<int> _count(
    jobs.ProcessingJobStatus status, {
    String? projectId,
  }) async {
    final String projectFilter = projectId == null
        ? ''
        : ' AND EXISTS (SELECT 1 FROM records r '
              'WHERE r.id = processing_jobs.record_id AND r.project_id = ?)';
    final QueryRow row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM processing_jobs WHERE status = ?'
          '$projectFilter',
          variables: <Variable<Object>>[
            Variable<String>(status.name),
            if (projectId != null) Variable<String>(projectId),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.processing,
            if (projectId != null) _db.records,
          },
        )
        .getSingle();
    return row.read<int>('c');
  }

  Future<QueueSnapshot> _snapshot({String? projectId}) async {
    final int queued = await _count(
      jobs.ProcessingJobStatus.queued,
      projectId: projectId,
    );
    final int running = await _count(
      jobs.ProcessingJobStatus.running,
      projectId: projectId,
    );
    final int failed = await _count(
      jobs.ProcessingJobStatus.failed,
      projectId: projectId,
    );
    final int unprocessed = await _unprocessed(projectId: projectId);
    final List<sqlite.ProcessingJobRow> failedRows = await _failedRows(
      projectId: projectId,
    );
    final ({int requests, int images}) usage = await _usageOn(
      _clock.nowUtc(),
      projectId: projectId,
    );
    return (
      unprocessed: unprocessed,
      queued: queued + running,
      failed: failed,
      requestsToday: usage.requests,
      imagesToday: usage.images,
      requestCap: _settings.read(SettingKeys.aiDailyRequestCap),
      groups: await _groups(projectId: projectId),
      failures: <ProcessingJob>[
        for (final sqlite.ProcessingJobRow row in failedRows) _toJob(row),
      ],
    );
  }

  Future<int> _unprocessed({String? projectId}) async {
    final String projectFilter = projectId == null ? '' : 'AND project_id = ? ';
    final QueryRow row = await _db
        .customSelect(
          "SELECT COUNT(*) AS c FROM records "
          "WHERE status IN ('CAPTURED', 'captured') "
          '$projectFilter'
          "AND NOT EXISTS ("
          "SELECT 1 FROM processing_jobs "
          "WHERE processing_jobs.record_id = records.id)",
          variables: <Variable<Object>>[
            if (projectId != null) Variable<String>(projectId),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.records,
            _db.processing,
          },
        )
        .getSingle();
    return row.read<int>('c');
  }

  Future<List<QueueGroup>> _groups({String? projectId}) async {
    final String projectFilter = projectId == null ? '' : 'AND project_id = ? ';
    final List<QueryRow> rows = await _db
        .customSelect(
          "SELECT context_json AS label, COUNT(*) AS n FROM records r "
          "WHERE status IN ('CAPTURED', 'captured', 'queued') "
          '$projectFilter'
          "AND (NOT EXISTS (SELECT 1 FROM processing_jobs pj "
          "WHERE pj.record_id = r.id) OR EXISTS ("
          "SELECT 1 FROM processing_jobs pj WHERE pj.record_id = r.id "
          "AND pj.status IN ('queued', 'running'))) "
          "GROUP BY context_json",
          variables: <Variable<Object>>[
            if (projectId != null) Variable<String>(projectId),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{_db.records},
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

  Future<List<sqlite.ProcessingJobRow>> _failedRows({String? projectId}) async {
    final JoinedSelectStatement<HasResultSet, Object?> query = _db
        .select(_db.processing)
        .join(<Join<HasResultSet, Object?>>[
          innerJoin(
            _db.records,
            _db.records.id.equalsExp(_db.processing.recordId),
          ),
        ]);
    query.where(
      _db.processing.status.equalsValue(jobs.ProcessingJobStatus.failed) &
          (projectId == null
              ? const Constant<bool>(true)
              : _db.records.projectId.equals(projectId)),
    );
    query.orderBy(<OrderingTerm>[OrderingTerm.asc(_db.processing.queuedAt)]);
    final List<TypedResult> rows = await query.get();
    return <sqlite.ProcessingJobRow>[
      for (final TypedResult row in rows) row.readTable(_db.processing),
    ];
  }

  Future<({int requests, int images})> _usageOn(
    DateTime day, {
    String? projectId,
  }) async {
    final DateTime start = DateTime.utc(day.year, day.month, day.day);
    final DateTime end = start.add(AppConstants.processing.dayWindow);
    final String projectFilter = projectId == null
        ? ''
        : 'AND r.project_id = ? ';
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT pr.request_summary FROM processing_results pr '
          'JOIN processing_jobs pj ON pj.id = pr.job_id '
          'JOIN records r ON r.id = pj.record_id '
          'WHERE pr.created_at >= ? AND pr.created_at < ? '
          '$projectFilter'
          'AND pr.request_summary LIKE ?',
          variables: <Variable<Object>>[
            Variable<DateTime>(start),
            Variable<DateTime>(end),
            if (projectId != null) Variable<String>(projectId),
            const Variable<String>('%"kind":"online"%'),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.processingResults,
            _db.processing,
            _db.records,
          },
        )
        .get();
    var images = 0;
    for (final QueryRow row in rows) {
      images += _imageCount(row.read<String>('request_summary'));
    }
    return (requests: rows.length, images: images);
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

/// Inserts one evidence-backed proposal without exposing a raw-column write
/// to the stage coordinator. The table helper enforces write-once semantics.
Future<Result<sqlite.RecordField>> insertProcessingProposal(
  sqlite.AppDatabase db, {
  required String recordId,
  required String fieldKey,
  required String rawValue,
  required String? normalisedValue,
  required double confidence,
  required String confidenceBand,
  required String source,
  required String method,
  required String provider,
  required String model,
  required String promptVersion,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  required String auditReason,
}) {
  sqlite.RecordFieldsCompanion insertProposalRow() {
    return sqlite.RecordFieldsCompanion(
      recordId: Value<String>(recordId),
      fieldKey: Value<String>(fieldKey),
      valueRaw: Value<String>(rawValue),
      valueRefined: Value<String?>(normalisedValue),
      confidence: Value<double>(confidence),
      confidenceBand: Value<String>(confidenceBand),
      source: Value<String>(source),
      method: Value<String>(method),
      provider: Value<String>(provider),
      model: Value<String>(model),
      promptVersion: Value<String>(promptVersion),
    );
  }

  return insertRecordField(
    db,
    row: insertProposalRow(),
    clock: clock,
    deviceId: deviceId,
    ids: ids,
    auditReason: auditReason,
  );
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
