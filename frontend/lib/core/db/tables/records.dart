import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/device_profile.dart';
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

  /// Template shape kept by this record until an explicit migration.
  /// Zero preserves an older recovery draft whose captured shape is unknown.
  IntColumn get templateVersion =>
      integer().withDefault(const Constant<int>(1))();

  /// Predefined checklist row, when the capture was against one.
  TextColumn get templateRowId => text().nullable()();

  /// How processing resolved [templateRowId], when it proposed one.
  TextColumn get rowMatchStrategy => text().nullable()();

  /// Confidence reported by the row matching strategy.
  RealColumn get rowMatchScore => real().nullable()();

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

  /// Backend account the capturing operator is enrolled as (§71.2). Null
  /// until this device is enrolled; enrolment annotates earlier records
  /// without rewriting [capturedBy].
  TextColumn get capturedByAccount => text().nullable()();

  /// GPS latitude at capture, when known.
  RealColumn get gpsLat => real().nullable()();

  /// GPS longitude at capture, when known.
  RealColumn get gpsLon => real().nullable()();

  /// When the record was approved, if it has been.
  DateTimeColumn get approvedAt => dateTime().nullable()();

  /// Operator who approved it.
  TextColumn get approvedBy => text().nullable()();

  /// Backend account the approving operator is enrolled as (§71.2).
  TextColumn get approvedByAccount => text().nullable()();

  /// Number shown in lists, counted per project from 1.
  ///
  /// Nullable so a package from an older build still inserts; the
  /// `records_number_ai` trigger then allocates the next number in the
  /// project. Not unique: two devices can number records independently until
  /// a merge relabels them.
  IntColumn get recordNumber => integer().nullable()();
}

/// Inserts or updates a record after refusing malformed [contextJson].
///
/// A record first written here carries the account this device's profile is
/// enrolled as in [Records.capturedByAccount] (§71.2); an update never
/// rewrites attribution.
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
  final Insertable<RecordRow> attributed;
  try {
    attributed = await _withAccount(database, row);
  } on Object catch (error) {
    return FailureResult<RecordRow>(storageFailureFrom(error));
  }
  return _RecordsDao(
    database,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).upsert(attributed);
}

/// [row] with the enrolled account when it creates a record that names none.
Future<Insertable<RecordRow>> _withAccount(
  AppDatabase db,
  Insertable<RecordRow> row,
) async {
  if (row is! RecordsCompanion || row.capturedByAccount.present) {
    return row;
  }
  if (row.id.present) {
    final String id = row.id.value;
    final TypedResult? existing =
        await (db.selectOnly(db.records)
              ..addColumns(<Expression<Object>>[db.records.id])
              ..where(db.records.id.equals(id)))
            .getSingleOrNull();
    if (existing != null) {
      return row;
    }
  }
  final String? account = await enrolledAccountId(db);
  if (account == null) {
    return row;
  }
  return row.copyWith(capturedByAccount: Value<String?>(account));
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

/// Every record with [identityHash], oldest capture first; empty when none
/// matches. Two records can share a hash (the duplicate outcome), so this is
/// a list: the caller sees both ids rather than a failure.
Future<Result<List<RecordRow>>> lookupRecordsByIdentityHash(
  GeneratedDatabase db, {
  required String identityHash,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<RecordRow> rows =
        await (database.select(database.records)
              ..where(
                ($RecordsTable tbl) => tbl.identityHash.equals(identityHash),
              )
              ..orderBy(<OrderClauseGenerator<$RecordsTable>>[
                ($RecordsTable tbl) => OrderingTerm.asc(tbl.capturedAt),
                ($RecordsTable tbl) => OrderingTerm.asc(tbl.id),
              ]))
            .get();
    return Success<List<RecordRow>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<RecordRow>>(failure);
  } on Object catch (error) {
    return FailureResult<List<RecordRow>>(storageFailureFrom(error));
  }
}

/// Audit `field_key` of every record status change, on entity `records`.
const String recordStatusAuditKey = 'status';

/// The stored spelling of [raw]: the matching [RecordSchema.statusNames]
/// entry once case and `_` are folded (`NEEDS_REVIEW` reads `needsReview`),
/// or [raw] unchanged when no status matches.
String canonicalRecordStatus(String raw) {
  final String folded = raw.replaceAll('_', '').toLowerCase();
  for (final String name in RecordSchema.statusNames) {
    if (name.toLowerCase() == folded) {
      return name;
    }
  }
  return raw;
}

/// Moves record [recordId] to [status] inside the caller's transaction.
///
/// Writes `status`, `updated_at`, `updated_by_device` and `rev + 1`; moving
/// to `approved` also stamps `approved_at` and `approved_by` ([operator]),
/// and leaving approved clears neither, so the history keeps them. Appends
/// one audit row: entity `records`, action updated, field key
/// [recordStatusAuditKey], [previousStatus] to [status], with [reason].
/// Both statuses are stored in their canonical spelling.
///
/// The move is not validated here: callers check it with the record
/// lifecycle first. Throws a [StorageFailure] when the record is not on this
/// device, so the caller's transaction rolls back.
Future<void> writeRecordStatus(
  GeneratedDatabase db, {
  required String recordId,
  required String status,
  required String previousStatus,
  Clock? clock,
  String? deviceId,
  String? operator,
  String? reason,
}) async {
  final AppDatabase database = db as AppDatabase;
  final DateTime now = (clock ?? const SystemClock()).nowUtc();
  final String device = deviceId ?? '';
  final String next = canonicalRecordStatus(status);
  final String previous = canonicalRecordStatus(previousStatus);
  final bool approving = next == _approvedStatus;
  await database.transaction(() async {
    final int changed = await database.customUpdate(
      approving
          // The approval carries the account this device is enrolled as
          // (§71.2), read in the same statement.
          ? 'UPDATE records SET status = ?, updated_at = ?, '
                'updated_by_device = ?, rev = rev + 1, approved_at = ?, '
                'approved_by = ?, approved_by_account = '
                '(SELECT account_id FROM device_profile WHERE id = ?) '
                'WHERE id = ?'
          : 'UPDATE records SET status = ?, updated_at = ?, '
                'updated_by_device = ?, rev = rev + 1 WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<String>(next),
        Variable<DateTime>(now),
        Variable<String>(device),
        if (approving) ...<Variable<Object>>[
          Variable<DateTime>(now),
          Variable<String>(operator),
          const Variable<String>(deviceProfileRowId),
        ],
        Variable<String>(recordId),
      ],
      updates: <TableInfo<dynamic, dynamic>>{database.records},
      updateKind: UpdateKind.update,
    );
    if (changed == 0) {
      throw StorageFailure(
        localizedMessage: Copy.messages.failureThatRecordIsNoLongerOnThis,
        localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
      );
    }
    await appendAudit(
      database,
      entityType: 'records',
      entityId: recordId,
      action: AuditAction.updated,
      fieldKey: recordStatusAuditKey,
      previousValue: previous,
      newValue: next,
      reason: reason,
      clock: clock,
      device: device,
      operator: operator,
    );
  });
}

const String _approvedStatus = 'approved';

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
    throw StorageFailure(
      localizedMessage: Copy.messages.failureTheRecordSContextCouldNotBe,
      localizedRecovery: Copy.messages.failureFixTheContextObjectAndSaveAgain,
    );
  }
  if (decoded is! Map) {
    throw StorageFailure(
      localizedMessage: Copy.messages.failureTheRecordSContextIsNotIn,
      localizedRecovery: Copy.messages.failureFixTheContextObjectAndSaveAgain,
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
