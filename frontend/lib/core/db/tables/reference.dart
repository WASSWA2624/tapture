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

part 'reference_rows.dart';

/// An imported lookup table. [projectId] is null when [scope] is global.
///
/// [columns] is the import-order JSON array. Re-importing the same
/// [sourceFile] updates this row rather than inserting a second dataset.
@DataClassName('ReferenceDatasetRow')
class Reference extends Table with MergeColumns {
  @override
  String get tableName => 'reference_datasets';

  /// Operator-facing name of the dataset.
  TextColumn get name => text()();

  /// Global or project.
  TextColumn get scope => textEnum<ReferenceScope>()();

  /// Owning project when [scope] is project.
  TextColumn get projectId => text().nullable()();

  /// Column used as the lookup key.
  TextColumn get keyColumn => text()();

  /// Column names JSON, in import order. An array, stored as text.
  TextColumn get columns => text()();

  /// Source path or name, stored as data, never interpolated into a query.
  TextColumn get sourceFile => text()();

  /// When this import was written.
  DateTimeColumn get importedAt => dateTime()();

  /// Number of rows currently stored for this dataset.
  IntColumn get rowCount => integer()();
}

/// Whether a [Reference] dataset is shared or project-scoped.
enum ReferenceScope {
  /// Visible to every project on the device.
  global,

  /// Visible only inside one project.
  project,
}

/// Inserts or updates a dataset after refusing malformed [columns] JSON.
Future<Result<ReferenceDatasetRow>> upsertReferenceDataset(
  GeneratedDatabase db, {
  required Insertable<ReferenceDatasetRow> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    _ensureDatasetWrite(row);
  } on Failure catch (failure) {
    return FailureResult<ReferenceDatasetRow>(failure);
  }
  final AppDatabase database = db as AppDatabase;
  return _ReferenceDao(
    database,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).upsert(row);
}

/// Inserts rows into [dataset], or updates that dataset in place when
/// [sourceFile] already exists at the same scope.
///
/// Matching rows keep their merge id. [keyNormalised] is computed here, never
/// at query time.
Future<Result<ReferenceDatasetRow>> importReferenceDataset(
  GeneratedDatabase db, {
  required Insertable<ReferenceDatasetRow> dataset,
  required Iterable<({String keyValue, Map<String, String> values})> rows,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    _ensureDatasetWrite(dataset);
  } on Failure catch (failure) {
    return FailureResult<ReferenceDatasetRow>(failure);
  }
  final AppDatabase database = db as AppDatabase;
  final List<({String keyValue, Map<String, String> values})> incoming =
      List<({String keyValue, Map<String, String> values})>.of(rows);
  return runInTransaction(database, () async {
    final String? sourceFile = _stringOf(dataset, 'source_file');
    final ReferenceScope? scope = _scopeOf(dataset);
    if (sourceFile == null || scope == null) {
      throw const StorageFailure(
        message: 'A dataset import needs a source file and a scope.',
        recoveryAction:
            'Choose the file and where it belongs, then import again.',
      );
    }
    final String? projectId = _stringOf(dataset, 'project_id');
    final ReferenceDatasetRow? existing = await _datasetForSource(
      database,
      sourceFile: sourceFile,
      scope: scope,
      projectId: projectId,
    );
    final Map<String, Expression<Object>> header =
        Map<String, Expression<Object>>.of(dataset.toColumns(false));
    final String datasetId = existing?.id ?? ids.newId();
    header['id'] = Variable<String>(datasetId);
    header['row_count'] = Variable<int>(incoming.length);
    if (existing != null) {
      header.remove('created_at');
    }
    final Result<ReferenceDatasetRow> written = await _ReferenceDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    ).upsert(RawValuesInsertable<ReferenceDatasetRow>(header));
    final ReferenceDatasetRow headerRow = switch (written) {
      Success<ReferenceDatasetRow>(:final ReferenceDatasetRow value) => value,
      FailureResult<ReferenceDatasetRow>(:final Failure failure) =>
        throw failure,
    };
    final DateTime now = clock.nowUtc();
    final $ReferenceRowsTable table = database.referenceRows;
    await database.batch((Batch batch) {
      for (final ({String keyValue, Map<String, String> values}) row
          in incoming) {
        final String folded = _foldReferenceKey(row.keyValue);
        final String json = jsonEncode(row.values);
        final ReferenceRowsCompanion companion = ReferenceRowsCompanion(
          id: Value<String>(ids.newId()),
          createdAt: Value<DateTime>(now),
          updatedAt: Value<DateTime>(now),
          updatedByDevice: Value<String>(deviceId),
          datasetId: Value<String>(datasetId),
          keyValue: Value<String>(row.keyValue),
          keyNormalised: Value<String>(folded),
          values: Value<String>(json),
        );
        if (existing == null) {
          batch.insert(table, companion);
        } else {
          batch.insert(
            table,
            companion,
            onConflict: DoUpdate(
              ($ReferenceRowsTable old) => ReferenceRowsCompanion.custom(
                keyNormalised: Variable<String>(folded),
                values: Variable<String>(json),
                updatedAt: Variable<DateTime>(now),
                updatedByDevice: Variable<String>(deviceId),
                rev: old.rev + const Constant<int>(1),
              ),
              target: <Column<Object>>[table.datasetId, table.keyValue],
            ),
          );
        }
      }
    });
    final int count = await _countRows(database, datasetId);
    if (count != headerRow.rowCount) {
      final Result<ReferenceDatasetRow> counted =
          await _ReferenceDao(
            database,
            clock: clock,
            deviceId: deviceId,
            ids: ids,
          ).upsert(
            ReferenceCompanion(
              id: Value<String>(datasetId),
              rowCount: Value<int>(count),
            ),
          );
      return switch (counted) {
        Success<ReferenceDatasetRow>(:final ReferenceDatasetRow value) => value,
        FailureResult<ReferenceDatasetRow>(:final Failure failure) =>
          throw failure,
      };
    }
    return headerRow;
  });
}

/// Inserts or updates a row after computing [ReferenceLookupRow.keyNormalised]
/// from [ReferenceLookupRow.keyValue].
Future<Result<ReferenceLookupRow>> upsertReferenceRow(
  GeneratedDatabase db, {
  required Insertable<ReferenceLookupRow> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    _ensureJsonObject(columns['values']);
    final String? keyValue = _stringExpression(columns['key_value']);
    if (keyValue != null) {
      columns['key_normalised'] = Variable<String>(_foldReferenceKey(keyValue));
    }
    final AppDatabase database = db as AppDatabase;
    return _ReferenceRowsDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    ).upsert(RawValuesInsertable<ReferenceLookupRow>(columns));
  } on Failure catch (failure) {
    return FailureResult<ReferenceLookupRow>(failure);
  } on Object catch (error) {
    return FailureResult<ReferenceLookupRow>(storageFailureFrom(error));
  }
}

/// The row whose [ReferenceLookupRow.keyValue] equals [keyValue], bound as a
/// parameter so imported text is never interpolated into SQL.
Future<Result<ReferenceLookupRow?>> lookupReferenceRowByKey(
  GeneratedDatabase db, {
  required String datasetId,
  required String keyValue,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final ReferenceLookupRow? row =
        await (database.select(database.referenceRows)..where(
              ($ReferenceRowsTable tbl) =>
                  tbl.datasetId.equals(datasetId) &
                  tbl.keyValue.equals(keyValue),
            ))
            .getSingleOrNull();
    return Success<ReferenceLookupRow?>(row);
  } on Failure catch (failure) {
    return FailureResult<ReferenceLookupRow?>(failure);
  } on Object catch (error) {
    return FailureResult<ReferenceLookupRow?>(storageFailureFrom(error));
  }
}

/// Rows whose stored [ReferenceLookupRow.keyNormalised] matches the folded
/// [query]. The query is folded in Dart; the index is equality, not a scan.
Future<Result<List<ReferenceLookupRow>>> lookupReferenceRowsByNormalised(
  GeneratedDatabase db, {
  required String datasetId,
  required String query,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final String folded = _foldReferenceKey(query);
    final List<ReferenceLookupRow> rows =
        await (database.select(database.referenceRows)..where(
              ($ReferenceRowsTable tbl) =>
                  tbl.datasetId.equals(datasetId) &
                  tbl.keyNormalised.equals(folded),
            ))
            .get();
    return Success<List<ReferenceLookupRow>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<ReferenceLookupRow>>(failure);
  } on Object catch (error) {
    return FailureResult<List<ReferenceLookupRow>>(storageFailureFrom(error));
  }
}

void _ensureDatasetWrite(Insertable<ReferenceDatasetRow> row) {
  _ensureJsonArray(row.toColumns(false)['columns']);
  final ReferenceScope? scope = _scopeOf(row);
  final String? projectId = _stringOf(row, 'project_id');
  if (scope == ReferenceScope.project &&
      (projectId == null || projectId.isEmpty)) {
    throw const StorageFailure(
      message: 'A project dataset needs a project.',
      recoveryAction: 'Choose the project, then import again.',
    );
  }
  if (scope == ReferenceScope.global && projectId != null) {
    throw const StorageFailure(
      message: 'A global dataset cannot belong to one project.',
      recoveryAction: 'Clear the project, then import again.',
    );
  }
}

void _ensureJsonArray(Expression<Object>? expression) {
  final String? raw = _stringExpression(expression);
  if (raw == null) {
    return;
  }
  final Object decoded = _decodeJson(raw);
  if (decoded is! List) {
    throw const StorageFailure(
      message: 'Dataset columns must be a JSON array.',
      recoveryAction: 'Fix the column list and save again.',
    );
  }
}

void _ensureJsonObject(Expression<Object>? expression) {
  final String? raw = _stringExpression(expression);
  if (raw == null) {
    return;
  }
  final Object decoded = _decodeJson(raw);
  if (decoded is! Map) {
    throw const StorageFailure(
      message: 'A reference row must be a JSON object.',
      recoveryAction: 'Fix the row values and save again.',
    );
  }
}

Object _decodeJson(String raw) {
  try {
    return jsonDecode(raw) as Object;
  } on FormatException {
    throw const StorageFailure(
      message: 'That JSON is not valid.',
      recoveryAction: 'Fix the JSON and save again.',
    );
  }
}

String? _stringOf(Insertable<ReferenceDatasetRow> row, String column) {
  return _stringExpression(row.toColumns(false)[column]);
}

ReferenceScope? _scopeOf(Insertable<ReferenceDatasetRow> row) {
  final Expression<Object>? expression = row.toColumns(false)['scope'];
  if (expression is Variable<ReferenceScope>) {
    return expression.value;
  }
  if (expression is Variable<String>) {
    final String? name = expression.value;
    if (name == null) {
      return null;
    }
    for (final ReferenceScope scope in ReferenceScope.values) {
      if (scope.name == name) {
        return scope;
      }
    }
  }
  return null;
}

String? _stringExpression(Expression<Object>? expression) {
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

Future<ReferenceDatasetRow?> _datasetForSource(
  AppDatabase db, {
  required String sourceFile,
  required ReferenceScope scope,
  required String? projectId,
}) {
  final SimpleSelectStatement<$ReferenceTable, ReferenceDatasetRow> query =
      db.select(db.reference)..where(
        ($ReferenceTable tbl) =>
            tbl.sourceFile.equals(sourceFile) & tbl.scope.equalsValue(scope),
      );
  if (projectId == null) {
    query.where(($ReferenceTable tbl) => tbl.projectId.isNull());
  } else {
    query.where(($ReferenceTable tbl) => tbl.projectId.equals(projectId));
  }
  return query.getSingleOrNull();
}

Future<int> _countRows(AppDatabase db, String datasetId) async {
  final QueryRow row = await db
      .customSelect(
        'SELECT COUNT(*) AS c FROM reference_rows WHERE dataset_id = ?',
        variables: <Variable<String>>[Variable<String>(datasetId)],
        readsFrom: <TableInfo<Table, Object?>>{db.referenceRows},
      )
      .getSingle();
  return row.read<int>('c');
}

/// Case-folded, accent-stripped, whitespace-collapsed lookup key.
String _foldReferenceKey(String value) {
  return _stripAccents(
    value.trim().toLowerCase(),
  ).replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _stripAccents(String value) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in value.runes) {
    if (rune >= 0x0300 && rune <= 0x036F) {
      continue;
    }
    buffer.write(_accentFold[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}

const Map<int, String> _accentFold = <int, String>{
  0xC0: 'a',
  0xC1: 'a',
  0xC2: 'a',
  0xC3: 'a',
  0xC4: 'a',
  0xC5: 'a',
  0xE0: 'a',
  0xE1: 'a',
  0xE2: 'a',
  0xE3: 'a',
  0xE4: 'a',
  0xE5: 'a',
  0xC7: 'c',
  0xE7: 'c',
  0xC8: 'e',
  0xC9: 'e',
  0xCA: 'e',
  0xCB: 'e',
  0xE8: 'e',
  0xE9: 'e',
  0xEA: 'e',
  0xEB: 'e',
  0xCC: 'i',
  0xCD: 'i',
  0xCE: 'i',
  0xCF: 'i',
  0xEC: 'i',
  0xED: 'i',
  0xEE: 'i',
  0xEF: 'i',
  0xD1: 'n',
  0xF1: 'n',
  0xD2: 'o',
  0xD3: 'o',
  0xD4: 'o',
  0xD5: 'o',
  0xD6: 'o',
  0xF2: 'o',
  0xF3: 'o',
  0xF4: 'o',
  0xF5: 'o',
  0xF6: 'o',
  0xD8: 'o',
  0xF8: 'o',
  0xD9: 'u',
  0xDA: 'u',
  0xDB: 'u',
  0xDC: 'u',
  0xF9: 'u',
  0xFA: 'u',
  0xFB: 'u',
  0xFC: 'u',
  0xDD: 'y',
  0xFD: 'y',
  0xFF: 'y',
  0xC6: 'ae',
  0xE6: 'ae',
  0xDF: 'ss',
  0x152: 'oe',
  0x153: 'oe',
};

final class _ReferenceDao extends BaseDao<Reference, ReferenceDatasetRow> {
  _ReferenceDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.reference);
}
