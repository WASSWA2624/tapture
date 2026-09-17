import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// As-recorded versus as-found difference for one field. Unique on
/// [recordId] plus [fieldKey].
///
/// Computation writes the two values and a status. A person writes
/// [resolvedBy] and [resolvedAt]; nothing is auto-resolved.
@TableIndex(
  name: 'variances_by_field',
  columns: {#recordId, #fieldKey},
  unique: true,
)
@TableIndex(name: 'variances_by_project_status', columns: {#projectId, #status})
class Variances extends Table with MergeColumns {
  /// Project this variance belongs to. The review list filters on it.
  TextColumn get projectId => text()();

  /// Record the two values were taken from.
  TextColumn get recordId => text()();

  /// Template field key that differs.
  TextColumn get fieldKey => text()();

  /// Value as recorded, stored as data.
  TextColumn get registerValue => text().nullable()();

  /// Value as found, stored as data.
  TextColumn get foundValue => text().nullable()();

  /// Queue or classification status, stored as text.
  TextColumn get status => text()();

  /// Operator who resolved it.
  TextColumn get resolvedBy => text().nullable()();

  /// When it was resolved.
  DateTimeColumn get resolvedAt => dateTime().nullable()();
}

/// Inserts a variance, or updates the existing row for the same field.
///
/// Computation never writes [Variance.resolvedBy] or [Variance.resolvedAt].
Future<Result<Variance>> upsertVariance(
  GeneratedDatabase db, {
  required Insertable<Variance> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    columns.remove('resolved_by');
    columns.remove('resolved_at');
    final String? recordId = _stringExpression(columns['record_id']);
    final String? fieldKey = _stringExpression(columns['field_key']);
    if (recordId != null && fieldKey != null) {
      final Variance? existing = await _varianceOf(
        database,
        recordId: recordId,
        fieldKey: fieldKey,
      );
      if (existing != null) {
        columns['id'] = Variable<String>(existing.id);
        columns.remove('created_at');
      }
    }
    return _VariancesDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    ).upsert(RawValuesInsertable<Variance>(columns));
  } on Failure catch (failure) {
    return FailureResult<Variance>(failure);
  } on Object catch (error) {
    return FailureResult<Variance>(storageFailureFrom(error));
  }
}

/// Records a person's resolution. The source record is left intact.
Future<Result<Variance>> resolveVariance(
  GeneratedDatabase db, {
  required String id,
  required String resolvedBy,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    if (resolvedBy.isEmpty) {
      throw const StorageFailure(
        message: 'A resolution needs an operator.',
        recoveryAction: 'Sign in, then resolve the variance again.',
      );
    }
    final AppDatabase database = db as AppDatabase;
    final Variance? existing = await (database.select(
      database.variances,
    )..where(($VariancesTable tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw const StorageFailure(
        message: 'That variance is no longer on this device.',
        recoveryAction: 'Refresh the list and try again.',
      );
    }
    return _VariancesDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    ).upsert(
      VariancesCompanion(
        id: Value<String>(id),
        resolvedBy: Value<String>(resolvedBy),
        resolvedAt: Value<DateTime>(clock.nowUtc()),
      ),
    );
  } on Failure catch (failure) {
    return FailureResult<Variance>(failure);
  } on Object catch (error) {
    return FailureResult<Variance>(storageFailureFrom(error));
  }
}

/// A page of variances in [projectId] with [status], oldest first.
///
/// The `WHERE project_id AND status` shape is what
/// `variances_by_project_status` was created to serve.
Future<Result<List<Variance>>> listVariancesByProjectAndStatus(
  GeneratedDatabase db, {
  required String projectId,
  required String status,
  required int offset,
  required int limit,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<Variance> rows =
        await (database.select(database.variances)
              ..where(
                ($VariancesTable tbl) =>
                    tbl.projectId.equals(projectId) & tbl.status.equals(status),
              )
              ..orderBy(<OrderClauseGenerator<$VariancesTable>>[
                ($VariancesTable tbl) => OrderingTerm.asc(tbl.createdAt),
                ($VariancesTable tbl) => OrderingTerm.asc(tbl.id),
              ])
              ..limit(limit, offset: offset))
            .get();
    return Success<List<Variance>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<Variance>>(failure);
  } on Object catch (error) {
    return FailureResult<List<Variance>>(storageFailureFrom(error));
  }
}

Future<Variance?> _varianceOf(
  AppDatabase db, {
  required String recordId,
  required String fieldKey,
}) {
  return (db.select(db.variances)..where(
        ($VariancesTable tbl) =>
            tbl.recordId.equals(recordId) & tbl.fieldKey.equals(fieldKey),
      ))
      .getSingleOrNull();
}

String? _stringExpression(Expression<Object>? expression) {
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

final class _VariancesDao extends BaseDao<Variances, Variance> {
  _VariancesDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.variances);
}
