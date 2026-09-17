import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// A template header: source, version and the project it belongs to.
///
/// [projectId] is null for shipped entries so they can sit beside
/// project-scoped copies. An edit bumps [version] rather than rewriting
/// history, so captured records keep the version they were taken against.
class Templates extends Table with MergeColumns {
  /// Owning project, or null when this row is a shipped template.
  TextColumn get projectId => text().nullable()();

  /// Display name.
  TextColumn get name => text()();

  /// Kind of thing this template captures, stored as data.
  TextColumn get kind => text()();

  /// Where the template came from (shipped, imported, built).
  TextColumn get source => text()();

  /// Imported workbook path, when [source] is an import.
  TextColumn get sourceFilePath => text().nullable()();

  /// Imported sheet name, stored as data, never interpolated into a query.
  TextColumn get sheetName => text().nullable()();

  /// 1-based header row in the imported sheet, when known.
  IntColumn get headerRow => integer().nullable()();

  /// Identity field keys JSON, stored as text.
  TextColumn get identityFields => text().withDefault(const Constant('[]'))();

  /// Detection profile JSON, stored as text.
  TextColumn get detection => text().withDefault(const Constant('{}'))();

  /// Structural version. Captured records keep the value they were taken at.
  IntColumn get version => integer().withDefault(const Constant(1))();
}

/// Inserts a template, or updates one and bumps [Template.version].
Future<Result<Template>> upsertTemplate(
  GeneratedDatabase db, {
  required Insertable<Template> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  final AppDatabase database = db as AppDatabase;
  final _TemplatesDao dao = _TemplatesDao(
    database,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  );
  final String? id = _idOf(row);
  if (id != null) {
    final Result<Template?> loaded = await dao.getById(id);
    switch (loaded) {
      case FailureResult<Template?>(:final Failure failure):
        return FailureResult<Template>(failure);
      case Success<Template?>(:final Template? value):
        if (value != null) {
          final Map<String, Expression<Object>> columns =
              Map<String, Expression<Object>>.of(row.toColumns(false));
          columns['version'] = Variable<int>(value.version + 1);
          return dao.upsert(RawValuesInsertable<Template>(columns));
        }
    }
  }
  return dao.upsert(row);
}

String? _idOf(Insertable<Template> row) {
  final Expression<Object>? expression = row.toColumns(false)['id'];
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

final class _TemplatesDao extends BaseDao<Templates, Template> {
  _TemplatesDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.templates);
}
