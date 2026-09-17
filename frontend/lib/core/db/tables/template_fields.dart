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

/// One column on a template. Unique on [templateId] plus [fieldKey].
class TemplateFields extends Table with MergeColumns {
  /// Template this field belongs to.
  TextColumn get templateId => text()();

  /// Stable key within the template. Duplicate keys are a unique constraint.
  TextColumn get fieldKey => text()();

  /// Operator-facing label, stored as data.
  TextColumn get label => text()();

  /// Field type name, stored as data.
  TextColumn get type => text()();

  /// Spreadsheet column or generated header this field writes to.
  TextColumn get outputColumn => text().nullable()();

  /// Whether a first capture must fill this field.
  ///
  /// Dart cannot name a companion field `required`, so the SQL column is
  /// `required` and the getter is [isRequired].
  BoolColumn get isRequired =>
      boolean().named('required').withDefault(const Constant(false))();

  /// How the value is entered.
  TextColumn get inputMode => text().withDefault(const Constant(''))();

  /// Whether the last value sticks onto the next record.
  BoolColumn get stickable => boolean().withDefault(const Constant(false))();

  /// Context hierarchy level this field binds to, when it does.
  IntColumn get contextLevel => integer().nullable()();

  /// Whether capture copies this value from context or a previous record.
  BoolColumn get autoFill => boolean().withDefault(const Constant(false))();

  /// Default written when the operator leaves the field empty.
  TextColumn get defaultValue => text().nullable()();

  /// Choice options JSON. An object or array, validated on write.
  TextColumn get options => text().withDefault(const Constant('[]'))();

  /// Unit label, when the type has one.
  TextColumn get unit => text().nullable()();

  /// Validation JSON. An object or array, validated on write.
  TextColumn get validation => text().withDefault(const Constant('{}'))();

  /// Lookup JSON. An object or array, validated on write.
  TextColumn get lookup => text().withDefault(const Constant('{}'))();

  /// Whether AI may propose a refined value beside the raw one.
  BoolColumn get refine => boolean().withDefault(const Constant(false))();

  /// List order. Reads sort by this, then [label].
  IntColumn get sortOrder => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{templateId, fieldKey},
  ];
}

/// Inserts or updates a field after refusing malformed JSON columns.
///
/// A second row with the same [templateId] and [fieldKey] is refused by the
/// unique index, not by a check in this function.
Future<Result<TemplateField>> upsertTemplateField(
  GeneratedDatabase db, {
  required Insertable<TemplateField> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    _ensureJsonColumns(row, const <String>['options', 'validation', 'lookup']);
  } on Failure catch (failure) {
    return FailureResult<TemplateField>(failure);
  }
  final AppDatabase database = db as AppDatabase;
  return _TemplateFieldsDao(
    database,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).upsert(row);
}

/// Fields of [templateId], in [TemplateField.sortOrder] then label order.
Future<Result<List<TemplateField>>> listTemplateFields(
  GeneratedDatabase db, {
  required String templateId,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<TemplateField> rows =
        await (database.select(database.templateFields)
              ..where(
                ($TemplateFieldsTable tbl) => tbl.templateId.equals(templateId),
              )
              ..orderBy(<OrderClauseGenerator<$TemplateFieldsTable>>[
                ($TemplateFieldsTable tbl) => OrderingTerm.asc(tbl.sortOrder),
                ($TemplateFieldsTable tbl) => OrderingTerm.asc(tbl.label),
              ]))
            .get();
    return Success<List<TemplateField>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<TemplateField>>(failure);
  } on Object catch (error) {
    return FailureResult<List<TemplateField>>(storageFailureFrom(error));
  }
}

void _ensureJsonColumns(Insertable<TemplateField> row, List<String> columns) {
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

final class _TemplateFieldsDao extends BaseDao<TemplateFields, TemplateField> {
  _TemplateFieldsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.templateFields);
}
