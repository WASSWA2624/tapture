import 'package:drift/drift.dart';
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

import '../domain/processing_repository.dart';
import 'processing_job_mapper.dart';
import 'processing_queue_queries.dart';
import 'processing_queue_writes.dart';

/// Drift-backed [ProcessingRepository].
///
/// Row reads and writes live here. Queue state changes are in
/// [ProcessingQueueWrites] and the queue screen's queries in
/// [ProcessingQueueQueries].
final class ProcessingRepositoryImpl implements ProcessingRepository {
  /// Opens against [db]. [settings] supplies the concurrency cap and the
  /// daily request cap.
  factory ProcessingRepositoryImpl({
    required sqlite.AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    required SettingsStore settings,
  }) {
    final ProcessingQueueQueries queries = ProcessingQueueQueries(
      db: db,
      clock: clock,
      settings: settings,
    );
    return ProcessingRepositoryImpl._(
      db: db,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
      queries: queries,
      writes: ProcessingQueueWrites(
        db: db,
        clock: clock,
        deviceId: deviceId,
        ids: ids,
        settings: settings,
        queries: queries,
      ),
    );
  }

  ProcessingRepositoryImpl._({
    required sqlite.AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    required this._queries,
    required this._writes,
  }) : _db = db,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids,
       _dao = _JobDao(db, clock: clock, deviceId: deviceId, ids: ids);

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final ProcessingQueueQueries _queries;
  final ProcessingQueueWrites _writes;
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
          if (!gone.contains(row.id)) ProcessingJobMapper.toJob(row),
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
        .asyncMap((_) => _queries.snapshot(projectId: projectId));
  }

  @override
  Future<Result<ProcessingJob?>> byId(String id) async {
    try {
      if ((await _tombstones()).contains(id)) {
        return const Success<ProcessingJob?>(null);
      }
      final sqlite.ProcessingJobRow? row =
          await (_db.select(_db.processing)
                ..where((sqlite.$ProcessingTable tbl) => tbl.id.equals(id)))
              .getSingleOrNull();
      return Success<ProcessingJob?>(
        row == null ? null : ProcessingJobMapper.toJob(row),
      );
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
          row: ProcessingJobMapper.toCompanion(
            job.copyWith(id: id),
            queuedAt: _clock.nowUtc(),
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        );
    return written.map(ProcessingJobMapper.toJob);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) {
    return _dao.softDelete(id, reason: reason);
  }

  @override
  Future<Result<int>> enqueuePending({
    String? projectId,
    List<String> groupLabels = const <String>[],
  }) {
    return _writes.enqueuePending(
      projectId: projectId,
      groupLabels: groupLabels,
    );
  }

  @override
  Future<Result<String>> enqueue(String recordId) {
    return _writes.enqueue(recordId);
  }

  @override
  Future<Result<ProcessingJob?>> claim(
    Duration lease, {
    String? projectId,
    List<String> groupLabels = const <String>[],
    JobStage? unfinished,
    Set<String> skip = const <String>{},
  }) {
    return _writes.claim(
      lease,
      projectId: projectId,
      groupLabels: groupLabels,
      unfinished: unfinished,
      skip: skip,
    );
  }

  @override
  Future<Result<void>> complete(String jobId) => _writes.complete(jobId);

  @override
  Future<Result<void>> fail(
    String jobId,
    String reason, {
    required bool permanent,
  }) {
    return _writes.fail(jobId, reason, permanent: permanent);
  }

  @override
  Future<Result<ProcessingJob>> markStage(String id, JobStage stage) {
    return _writes.markStage(id, stage);
  }

  @override
  Future<Result<void>> release(String id) => _writes.release(id);

  @override
  Future<Result<void>> retry(String id) => _writes.retry(id);

  @override
  Future<Result<({int requests, int images})>> usageOn(
    DateTime day, {
    String? projectId,
  }) async {
    try {
      return Success<({int requests, int images})>(
        await _queries.usageOn(day, projectId: projectId),
      );
    } on Object catch (error) {
      return FailureResult<({int requests, int images})>(
        storageFailureFrom(error),
      );
    }
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
