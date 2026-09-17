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

/// A predefined checklist row on a template, with aliases for local names.
@TableIndex(
  name: 'template_rows_by_identifier',
  columns: {#templateId, #identifier},
)
class TemplateRows extends Table with MergeColumns {
  /// Template this row belongs to.
  TextColumn get templateId => text()();

  /// Original spreadsheet row number, kept for write-back.
  IntColumn get outputRowNumber => integer()();

  /// Stable identifier within the template.
  TextColumn get identifier => text()();

  /// Operator-facing label, stored as data.
  TextColumn get label => text()();

  /// Alias list JSON. An object or array, validated on write.
  TextColumn get aliases => text().withDefault(const Constant('[]'))();

  /// Extra row JSON. An object or array, validated on write.
  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  /// Found / missing status for the capture checklist.
  TextColumn get foundStatus => text().withDefault(const Constant('missing'))();
}

/// Inserts or updates a row after refusing malformed JSON columns.
Future<Result<TemplateRow>> upsertTemplateRow(
  GeneratedDatabase db, {
  required Insertable<TemplateRow> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    _ensureJsonColumns(row, const <String>['aliases', 'metadata']);
  } on Failure catch (failure) {
    return FailureResult<TemplateRow>(failure);
  }
  final AppDatabase database = db as AppDatabase;
  return _TemplateRowsDao(
    database,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).upsert(row);
}

/// Finds a checklist row by identifier, label or alias.
///
/// The template id is bound as a parameter. Alias text is matched in Dart so
/// imported cell values are never interpolated into SQL (FE-SEC-05).
Future<Result<TemplateRow?>> lookupTemplateRow(
  GeneratedDatabase db, {
  required String templateId,
  required String query,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<TemplateRow> rows =
        await (database.select(database.templateRows)..where(
              ($TemplateRowsTable tbl) => tbl.templateId.equals(templateId),
            ))
            .get();
    final String needle = query.trim().toLowerCase();
    for (final TemplateRow row in rows) {
      if (_matchesAlias(row, needle)) {
        return Success<TemplateRow?>(row);
      }
    }
    return const Success<TemplateRow?>(null);
  } on Failure catch (failure) {
    return FailureResult<TemplateRow?>(failure);
  } on Object catch (error) {
    return FailureResult<TemplateRow?>(storageFailureFrom(error));
  }
}

bool _matchesAlias(TemplateRow row, String needle) {
  if (row.identifier.toLowerCase() == needle ||
      row.label.toLowerCase() == needle) {
    return true;
  }
  late final Object? decoded;
  try {
    decoded = jsonDecode(row.aliases) as Object?;
  } on FormatException {
    return false;
  }
  if (decoded is! List) {
    return false;
  }
  for (final Object? alias in decoded) {
    if (alias is String && alias.trim().toLowerCase() == needle) {
      return true;
    }
  }
  return false;
}

void _ensureJsonColumns(Insertable<TemplateRow> row, List<String> columns) {
  final Map<String, Expression<Object>> written = row.toColumns(false);
  for (final String column in columns) {
    final Expression<Object>? expression = written[column];
    if (expression is! Variable<String>) {
      continue;
    }
    final String? value = expression.value;
    if (value == null) {
      continue;
    }
    _parseJsonDocument(value);
  }
}

void _parseJsonDocument(String raw) {
  late final Object? decoded;
  try {
    decoded = jsonDecode(raw) as Object?;
  } on FormatException {
    throw const StorageFailure(
      message: 'That JSON is not valid.',
      recoveryAction: 'Fix the JSON and save again.',
    );
  }
  if (decoded is Map || decoded is List) {
    return;
  }
  throw const StorageFailure(
    message: 'That JSON must be an object or an array.',
    recoveryAction: 'Fix the JSON and save again.',
  );
}

final class _TemplateRowsDao extends BaseDao<TemplateRows, TemplateRow> {
  _TemplateRowsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.templateRows);
}
