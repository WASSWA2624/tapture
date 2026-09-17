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

/// One completed export of a project. Unique on [projectId] plus [version].
///
/// [filePath] and [fileHash] are written when the file is finished. A
/// re-export inserts a new row; an abandoned run inserts none.
@TableIndex(
  name: 'exports_by_project_created',
  columns: {#projectId, #createdAt},
)
@DataClassName('ExportRow')
class Exports extends Table with MergeColumns {
  /// Project this export belongs to.
  TextColumn get projectId => text()();

  /// Per-project sequence. Successive exports increment this.
  IntColumn get version => integer()();

  /// Formats written, as a JSON array.
  TextColumn get formats => text()();

  /// Query that selected the records. An object, never the exported values.
  TextColumn get filters => text()();

  /// How many records the file contains.
  IntColumn get recordCount => integer()();

  /// Path of the finished file. Written once at insert.
  TextColumn get filePath => text()();

  /// Hash of the finished file. Written once at insert.
  TextColumn get fileHash => text()();

  /// Operator who produced the file.
  TextColumn get createdBy => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{projectId, version},
  ];
}

/// Records a finished export. [produce] must return path and hash; if it
/// throws, no row is written.
///
/// [ExportRow.version] is allocated here, per project, so the caller never
/// chooses it.
Future<Result<ExportRow>> completeExport(
  GeneratedDatabase db, {
  required Future<Insertable<ExportRow>> Function() produce,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    final Insertable<ExportRow> row = await produce();
    _ensureCompleted(row);
    final AppDatabase database = db as AppDatabase;
    return runInTransaction(database, () async {
      final Map<String, Expression<Object>> columns =
          Map<String, Expression<Object>>.of(row.toColumns(false));
      final String? id = _stringExpression(columns['id']);
      if (id != null) {
        final ExportRow? existing = await (database.select(
          database.exports,
        )..where(($ExportsTable tbl) => tbl.id.equals(id))).getSingleOrNull();
        if (existing != null) {
          throw const StorageFailure(
            message: 'A completed export cannot be changed.',
            recoveryAction: 'Run a new export instead of rewriting this one.',
          );
        }
      }
      final String projectId = _stringExpression(columns['project_id'])!;
      columns['version'] = Variable<int>(
        await _nextVersion(database, projectId),
      );
      final Result<ExportRow> written = await _ExportsDao(
        database,
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      ).upsert(RawValuesInsertable<ExportRow>(columns));
      return switch (written) {
        Success<ExportRow>(:final ExportRow value) => value,
        FailureResult<ExportRow>(:final Failure failure) => throw failure,
      };
    });
  } on Failure catch (failure) {
    return FailureResult<ExportRow>(failure);
  } on Object catch (error) {
    return FailureResult<ExportRow>(storageFailureFrom(error));
  }
}

/// A page of exports for [projectId], newest [ExportRow.createdAt] first.
///
/// The `WHERE project_id ORDER BY created_at DESC` shape is what
/// `exports_by_project_created` was created to serve.
Future<Result<List<ExportRow>>> listExportsForProject(
  GeneratedDatabase db, {
  required String projectId,
  required int offset,
  required int limit,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<ExportRow> rows =
        await (database.select(database.exports)
              ..where(($ExportsTable tbl) => tbl.projectId.equals(projectId))
              ..orderBy(<OrderClauseGenerator<$ExportsTable>>[
                ($ExportsTable tbl) => OrderingTerm.desc(tbl.createdAt),
                ($ExportsTable tbl) => OrderingTerm.desc(tbl.id),
              ])
              ..limit(limit, offset: offset))
            .get();
    return Success<List<ExportRow>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<ExportRow>>(failure);
  } on Object catch (error) {
    return FailureResult<List<ExportRow>>(storageFailureFrom(error));
  }
}

void _ensureCompleted(Insertable<ExportRow> row) {
  final Map<String, Expression<Object>> columns = row.toColumns(false);
  final String? projectId = _stringExpression(columns['project_id']);
  final String? filePath = _stringExpression(columns['file_path']);
  final String? fileHash = _stringExpression(columns['file_hash']);
  final String? createdBy = _stringExpression(columns['created_by']);
  if (projectId == null ||
      projectId.isEmpty ||
      filePath == null ||
      filePath.isEmpty ||
      fileHash == null ||
      fileHash.isEmpty ||
      createdBy == null ||
      createdBy.isEmpty) {
    throw const StorageFailure(
      message: 'An export is recorded only when the file is finished.',
      recoveryAction: 'Finish writing the file, then record the export.',
    );
  }
  _ensureJsonArray(columns['formats']);
  _ensureJsonObject(columns['filters']);
}

void _ensureJsonArray(Expression<Object>? expression) {
  final String? raw = _stringExpression(expression);
  if (raw == null) {
    throw const StorageFailure(
      message: 'Export formats must be a JSON array.',
      recoveryAction: 'Fix the formats list and save again.',
    );
  }
  final Object decoded = _decodeJson(raw);
  if (decoded is! List) {
    throw const StorageFailure(
      message: 'Export formats must be a JSON array.',
      recoveryAction: 'Fix the formats list and save again.',
    );
  }
}

void _ensureJsonObject(Expression<Object>? expression) {
  final String? raw = _stringExpression(expression);
  if (raw == null) {
    throw const StorageFailure(
      message: 'Export filters must be a JSON object.',
      recoveryAction: 'Store the query, not the exported values.',
    );
  }
  final Object decoded = _decodeJson(raw);
  if (decoded is! Map) {
    throw const StorageFailure(
      message: 'Export filters must be a JSON object.',
      recoveryAction: 'Store the query, not the exported values.',
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

Future<int> _nextVersion(AppDatabase db, String projectId) async {
  final QueryRow row = await db
      .customSelect(
        'SELECT COALESCE(MAX(version), 0) AS v FROM exports '
        'WHERE project_id = ?',
        variables: <Variable<String>>[Variable<String>(projectId)],
        readsFrom: <TableInfo<Table, Object?>>{db.exports},
      )
      .getSingle();
  return row.read<int>('v') + 1;
}

String? _stringExpression(Expression<Object>? expression) {
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

final class _ExportsDao extends BaseDao<Exports, ExportRow> {
  _ExportsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.exports);
}
