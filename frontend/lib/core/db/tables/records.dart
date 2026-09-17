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

/// A captured record: status, frozen context and identity hash.
///
/// [contextJson] is the snapshot in force at capture, never a live join, so a
/// later context correction cannot rewrite what was captured. Dart's `Record`
/// type owns the obvious data-class name, so the row is [RecordRow].
@TableIndex(name: 'records_by_project_status', columns: {#projectId, #status})
@TableIndex(name: 'records_by_identity_hash', columns: {#identityHash})
@TableIndex(name: 'records_by_captured_at', columns: {#capturedAt})
@TableIndex(name: 'records_by_template', columns: {#templateId})
@DataClassName('RecordRow')
class Records extends Table with MergeColumns {
  /// Project this record belongs to.
  TextColumn get projectId => text()();

  /// Template used at capture.
  TextColumn get templateId => text()();

  /// Predefined checklist row, when the capture was against one.
  TextColumn get templateRowId => text().nullable()();

  /// Lifecycle status. Stored as text so this table does not import Flutter.
  TextColumn get status => text()();

  /// How the record is processed (manual, on-device, online).
  TextColumn get processingMode => text()();

  /// Context values in force at capture. An object, stored as text.
  TextColumn get contextJson => text()();

  /// Hash of identity fields, so two devices can recognise the same record.
  TextColumn get identityHash => text()();

  /// Where the record came from (capture, import, duplicate).
  TextColumn get source => text()();

  /// When the operator captured it.
  DateTimeColumn get capturedAt => dateTime()();

  /// Operator who captured it.
  TextColumn get capturedBy => text()();

  /// GPS latitude at capture, when known.
  RealColumn get gpsLat => real().nullable()();

  /// GPS longitude at capture, when known.
  RealColumn get gpsLon => real().nullable()();

  /// When the record was approved, if it has been.
  DateTimeColumn get approvedAt => dateTime().nullable()();

  /// Operator who approved it.
  TextColumn get approvedBy => text().nullable()();
}

/// Inserts or updates a record after refusing malformed [contextJson].
Future<Result<RecordRow>> upsertRecord(
  GeneratedDatabase db, {
  required Insertable<RecordRow> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    _ensureContextJson(row);
  } on Failure catch (failure) {
    return FailureResult<RecordRow>(failure);
  }
  final AppDatabase database = db as AppDatabase;
  return _RecordsDao(
    database,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).upsert(row);
}

/// A page of [projectId] records in [status], newest [RecordRow.capturedAt]
/// first.
///
/// The `WHERE project_id AND status` shape is what `records_by_project_status`
/// was created to serve.
Future<Result<List<RecordRow>>> listRecordsByProjectAndStatus(
  GeneratedDatabase db, {
  required String projectId,
  required String status,
  required int offset,
  required int limit,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<RecordRow> rows =
        await (database.select(database.records)
              ..where(
                ($RecordsTable tbl) =>
                    tbl.projectId.equals(projectId) & tbl.status.equals(status),
              )
              ..orderBy(<OrderClauseGenerator<$RecordsTable>>[
                ($RecordsTable tbl) => OrderingTerm.desc(tbl.capturedAt),
              ])
              ..limit(limit, offset: offset))
            .get();
    return Success<List<RecordRow>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<RecordRow>>(failure);
  } on Object catch (error) {
    return FailureResult<List<RecordRow>>(storageFailureFrom(error));
  }
}

/// The record with [identityHash], or null when none matches.
Future<Result<RecordRow?>> lookupRecordByIdentityHash(
  GeneratedDatabase db, {
  required String identityHash,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final RecordRow? row =
        await (database.select(database.records)..where(
              ($RecordsTable tbl) => tbl.identityHash.equals(identityHash),
            ))
            .getSingleOrNull();
    return Success<RecordRow?>(row);
  } on Failure catch (failure) {
    return FailureResult<RecordRow?>(failure);
  } on Object catch (error) {
    return FailureResult<RecordRow?>(storageFailureFrom(error));
  }
}

void _ensureContextJson(Insertable<RecordRow> row) {
  final Expression<Object>? expression = row.toColumns(false)['context_json'];
  if (expression is! Variable<String>) {
    return;
  }
  final String? json = expression.value;
  if (json == null) {
    return;
  }
  late final Object? decoded;
  try {
    decoded = jsonDecode(json) as Object?;
  } on FormatException {
    throw const StorageFailure(
      message: 'Record context is not valid JSON.',
      recoveryAction: 'Fix the context object and save again.',
    );
  }
  if (decoded is! Map) {
    throw const StorageFailure(
      message: 'Record context must be a JSON object.',
      recoveryAction: 'Fix the context object and save again.',
    );
  }
}

final class _RecordsDao extends BaseDao<Records, RecordRow> {
  _RecordsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.records);
}
