import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// One field value on a record. Unique on [recordId] plus [fieldKey].
///
/// The raw column is written once at insert. Refinement writes
/// [valueRefined]; approval writes [valueFinal].
@TableIndex(name: 'record_fields_by_final', columns: {#fieldKey, #valueFinal})
class RecordFields extends Table with MergeColumns {
  /// Record this value belongs to.
  TextColumn get recordId => text()();

  /// Template field key this value fills.
  TextColumn get fieldKey => text()();

  /// Original captured value. Written once at insert, never updated.
  TextColumn get valueRaw => text().nullable()();

  /// Refined value written beside the original, never over it.
  TextColumn get valueRefined => text().nullable()();

  /// Approved value used for export and search.
  TextColumn get valueFinal => text().nullable()();

  /// Confidence of a proposed refinement, when one exists.
  RealColumn get confidence => real().nullable()();

  /// Where this value came from (typed, lookup, extraction).
  TextColumn get source => text()();

  /// Whether an operator has verified the final value.
  BoolColumn get verified => boolean().withDefault(const Constant(false))();

  /// Operator who verified it.
  TextColumn get verifiedBy => text().nullable()();

  /// When it was verified.
  DateTimeColumn get verifiedAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{recordId, fieldKey},
  ];
}

/// Inserts a field row. A later write that includes the raw column is refused.
Future<Result<RecordField>> insertRecordField(
  GeneratedDatabase db, {
  required Insertable<RecordField> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
}) {
  return _writeRecordField(
    db,
    row: row,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
    operator: operator,
    allowRaw: true,
  );
}

/// Writes a refined value beside the original raw column.
Future<Result<RecordField>> writeRecordFieldRefined(
  GeneratedDatabase db, {
  required String id,
  required String valueRefined,
  double? confidence,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
}) {
  return _writeRecordField(
    db,
    row: RecordFieldsCompanion(
      id: Value<String>(id),
      valueRefined: Value<String>(valueRefined),
      confidence: confidence == null
          ? const Value<double?>.absent()
          : Value<double?>(confidence),
    ),
    clock: clock,
    deviceId: deviceId,
    ids: ids,
    operator: operator,
    allowRaw: false,
  );
}

/// Writes the approved final value. The raw column stays as captured.
Future<Result<RecordField>> writeRecordFieldFinal(
  GeneratedDatabase db, {
  required String id,
  required String valueFinal,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? verifiedBy,
  String? operator,
}) {
  final DateTime now = clock.nowUtc();
  return _writeRecordField(
    db,
    row: RecordFieldsCompanion(
      id: Value<String>(id),
      valueFinal: Value<String>(valueFinal),
      verified: const Value<bool>(true),
      verifiedBy: Value<String?>(verifiedBy),
      verifiedAt: Value<DateTime>(now),
    ),
    clock: clock,
    deviceId: deviceId,
    ids: ids,
    operator: operator,
    allowRaw: false,
  );
}

Future<Result<RecordField>> _writeRecordField(
  GeneratedDatabase db, {
  required Insertable<RecordField> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
  required bool allowRaw,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final _RecordFieldsDao dao = _RecordFieldsDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    final String? id = _idOf(row);
    final RecordField? existing = id == null
        ? null
        : (await dao.getById(id)).fold(
            (Failure failure) => throw failure,
            (RecordField? value) => value,
          );
    if (existing != null && columns.containsKey('value_raw')) {
      throw const StorageFailure(
        message: 'The original value cannot be changed.',
        recoveryAction: 'Leave the captured value and write a refined one.',
      );
    }
    if (!allowRaw) {
      columns.remove('value_raw');
    }
    return await database.transaction(() async {
      final Result<RecordField> written = await dao.upsert(
        RawValuesInsertable<RecordField>(columns),
      );
      switch (written) {
        case FailureResult<RecordField>():
          return written;
        case Success<RecordField>(:final RecordField value):
          await appendAudit(
            database,
            entityType: 'records',
            entityId: value.recordId,
            action: existing == null
                ? AuditAction.created
                : AuditAction.updated,
            fieldKey: value.fieldKey,
            previousValue: _auditPrevious(existing, columns),
            newValue: _auditNew(value, columns),
            clock: clock,
            device: deviceId,
            operator: operator,
          );
          return written;
      }
    });
  } on Failure catch (failure) {
    return FailureResult<RecordField>(failure);
  } on Object catch (error) {
    return FailureResult<RecordField>(storageFailureFrom(error));
  }
}

String? _idOf(Insertable<RecordField> row) {
  final Expression<Object>? expression = row.toColumns(false)['id'];
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

String? _auditPrevious(
  RecordField? existing,
  Map<String, Expression<Object>> columns,
) {
  if (existing == null) {
    return null;
  }
  if (columns.containsKey('value_final')) {
    return existing.valueFinal;
  }
  if (columns.containsKey('value_refined')) {
    return existing.valueRefined;
  }
  return existing.valueRaw;
}

String? _auditNew(RecordField value, Map<String, Expression<Object>> columns) {
  if (columns.containsKey('value_final')) {
    return value.valueFinal;
  }
  if (columns.containsKey('value_refined')) {
    return value.valueRefined;
  }
  return value.valueRaw;
}

/// Marks a field deleted without removing the row, so evidence can still
/// point at it.
Future<Result<void>> softDeleteRecordField(
  GeneratedDatabase db, {
  required String id,
  required String reason,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  return _RecordFieldsDao(
    db as AppDatabase,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).softDelete(id, reason: reason);
}

final class _RecordFieldsDao extends BaseDao<RecordFields, RecordField> {
  _RecordFieldsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.recordFields);
}
