import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

part 'processing_results.dart';

/// A deferred processing job for one record.
///
/// The queue reads `WHERE status ORDER BY queued_at`, which
/// [processing_jobs_by_status] was created to serve.
@TableIndex(name: 'processing_jobs_by_status', columns: {#status, #queuedAt})
@DataClassName('ProcessingJobRow')
class Processing extends Table with MergeColumns {
  @override
  String get tableName => 'processing_jobs';

  /// Record this job will process.
  TextColumn get recordId => text()();

  /// Last stage the runner reached, stored as data.
  TextColumn get stage => text()();

  /// queued, running, completed or failed.
  TextColumn get status => textEnum<ProcessingJobStatus>()();

  /// How many times this job has been retried.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Last failure reason, when one exists. Stored as data.
  TextColumn get lastError => text().nullable()();

  /// When the job entered the queue.
  DateTimeColumn get queuedAt => dateTime()();

  /// When a runner claimed it, if it has been claimed.
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// When the job last finished, if it has.
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// Provider name, when an online stage ran.
  TextColumn get provider => text().nullable()();

  /// Model name, when an online stage ran.
  TextColumn get model => text().nullable()();
}

/// Lifecycle of a [Processing] job.
enum ProcessingJobStatus {
  /// Waiting to be claimed.
  queued,

  /// Owned by one runner.
  running,

  /// Finished successfully.
  completed,

  /// Finished with a failure. A retry returns it to [queued].
  failed,
}

/// Inserts or updates a processing job.
Future<Result<ProcessingJobRow>> upsertProcessingJob(
  GeneratedDatabase db, {
  required Insertable<ProcessingJobRow> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  final AppDatabase database = db as AppDatabase;
  return _ProcessingDao(
    database,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).upsert(row);
}

/// Claims the oldest queued job in one transaction.
///
/// The update keeps `status = queued` in the WHERE clause so two runners
/// cannot take the same row.
Future<Result<ProcessingJobRow?>> claimNextProcessingJob(
  GeneratedDatabase db, {
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  final AppDatabase database = db as AppDatabase;
  return runInTransaction(database, () async {
    final ProcessingJobRow? next =
        await (database.select(database.processing)
              ..where(
                ($ProcessingTable tbl) =>
                    tbl.status.equalsValue(ProcessingJobStatus.queued),
              )
              ..orderBy(<OrderClauseGenerator<$ProcessingTable>>[
                ($ProcessingTable tbl) => OrderingTerm.asc(tbl.queuedAt),
                ($ProcessingTable tbl) => OrderingTerm.asc(tbl.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (next == null) {
      return null;
    }
    final DateTime now = clock.nowUtc();
    final int changed =
        await (database.update(database.processing)..where(
              ($ProcessingTable tbl) =>
                  tbl.id.equals(next.id) &
                  tbl.status.equalsValue(ProcessingJobStatus.queued),
            ))
            .write(
              ProcessingCompanion(
                status: const Value<ProcessingJobStatus>(
                  ProcessingJobStatus.running,
                ),
                startedAt: Value<DateTime>(now),
                updatedAt: Value<DateTime>(now),
                updatedByDevice: Value<String>(deviceId),
                rev: Value<int>(next.rev + 1),
              ),
            );
    if (changed == 0) {
      return null;
    }
    return (database.select(
      database.processing,
    )..where(($ProcessingTable tbl) => tbl.id.equals(next.id))).getSingle();
  });
}

/// Returns a finished job to the queue and adds one to [ProcessingJobRow.attempts].
Future<Result<ProcessingJobRow>> retryProcessingJob(
  GeneratedDatabase db, {
  required String id,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final _ProcessingDao dao = _ProcessingDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final ProcessingJobRow existing = (await dao.getById(id)).fold(
      (Failure failure) => throw failure,
      (ProcessingJobRow? value) {
        if (value == null) {
          throw const StorageFailure(
            message: 'That job is no longer on this device.',
            recoveryAction: 'Refresh the queue and try again.',
          );
        }
        return value;
      },
    );
    return dao.upsert(
      ProcessingCompanion(
        id: Value<String>(id),
        status: const Value<ProcessingJobStatus>(ProcessingJobStatus.queued),
        attempts: Value<int>(existing.attempts + 1),
        startedAt: const Value<DateTime?>(null),
        finishedAt: const Value<DateTime?>(null),
      ),
    );
  } on Failure catch (failure) {
    return FailureResult<ProcessingJobRow>(failure);
  } on Object catch (error) {
    return FailureResult<ProcessingJobRow>(storageFailureFrom(error));
  }
}

/// Appends a result row. [ProcessingResult.rawResponse] and
/// [ProcessingResult.requestSummary] are written once and never updated.
Future<Result<ProcessingResult>> insertProcessingResult(
  GeneratedDatabase db, {
  required Insertable<ProcessingResult> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    _ensureRequestSummary(row);
    final AppDatabase database = db as AppDatabase;
    final _ProcessingResultsDao dao = _ProcessingResultsDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final String? id = _resultIdOf(row);
    if (id != null) {
      final ProcessingResult? existing = (await dao.getById(id)).fold(
        (Failure failure) => throw failure,
        (ProcessingResult? value) => value,
      );
      if (existing != null) {
        throw const StorageFailure(
          message: 'A stored provider response cannot be changed.',
          recoveryAction: 'Leave the original result and write a new one.',
        );
      }
    }
    return dao.upsert(row);
  } on Failure catch (failure) {
    return FailureResult<ProcessingResult>(failure);
  } on Object catch (error) {
    return FailureResult<ProcessingResult>(storageFailureFrom(error));
  }
}

/// Results for [jobId], oldest first, including every retry.
Future<Result<List<ProcessingResult>>> listProcessingResults(
  GeneratedDatabase db, {
  required String jobId,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<ProcessingResult> rows =
        await (database.select(database.processingResults)
              ..where(($ProcessingResultsTable tbl) => tbl.jobId.equals(jobId))
              ..orderBy(<OrderClauseGenerator<$ProcessingResultsTable>>[
                ($ProcessingResultsTable tbl) =>
                    OrderingTerm.asc(tbl.createdAt),
                ($ProcessingResultsTable tbl) => OrderingTerm.asc(tbl.id),
              ]))
            .get();
    return Success<List<ProcessingResult>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<ProcessingResult>>(failure);
  } on Object catch (error) {
    return FailureResult<List<ProcessingResult>>(storageFailureFrom(error));
  }
}

void _ensureRequestSummary(Insertable<ProcessingResult> row) {
  final Expression<Object>? expression = row.toColumns(
    false,
  )['request_summary'];
  if (expression is! Variable<String>) {
    return;
  }
  final String? summary = expression.value;
  if (summary == null) {
    return;
  }
  if (summary.toLowerCase().contains('bearer ')) {
    throw const StorageFailure(
      message: 'A request summary cannot include a secret.',
      recoveryAction: 'Store shape and size only, then save again.',
    );
  }
  late final Object? decoded;
  try {
    decoded = jsonDecode(summary) as Object?;
  } on FormatException {
    return;
  }
  if (decoded is! Map) {
    return;
  }
  for (final Object? key in decoded.keys) {
    if (_isSecretSummaryKey(key.toString())) {
      throw const StorageFailure(
        message: 'A request summary cannot include a secret.',
        recoveryAction: 'Store shape and size only, then save again.',
      );
    }
  }
}

bool _isSecretSummaryKey(String key) {
  final String folded = key.toLowerCase().replaceAll(RegExp(r'[_-]'), '');
  return const <String>{
    'key',
    'apikey',
    'token',
    'accesstoken',
    'refreshtoken',
    'secret',
    'password',
    'authorization',
    'bearer',
    'credential',
  }.contains(folded);
}

String? _resultIdOf(Insertable<ProcessingResult> row) {
  final Expression<Object>? expression = row.toColumns(false)['id'];
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

final class _ProcessingDao extends BaseDao<Processing, ProcessingJobRow> {
  _ProcessingDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.processing);
}
