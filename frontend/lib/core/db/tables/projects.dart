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

/// A field project: identity, status, folder and validated settings.
@TableIndex(name: 'projects_by_status', columns: {#status, #updatedAt})
class Projects extends Table with MergeColumns {
  /// Display name. Changing this must not rewrite [folderName].
  TextColumn get name => text()();

  /// Client or organisation the project is for.
  TextColumn get client => text().withDefault(const Constant(''))();

  /// Active, archived or deleted. The list filters on this column.
  TextColumn get status => textEnum<ProjectStatus>()();

  /// When fieldwork started, if known.
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// When fieldwork finished, if known.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// On-disk folder. Stored at creation and never recomputed on read.
  TextColumn get folderName => text()();

  /// Project settings JSON. An object, validated before it is stored.
  TextColumn get settings => text()();
}

/// Lifecycle of a [Project] row.
enum ProjectStatus {
  /// Open for capture and listed by default.
  active,

  /// Hidden from the default list; reversible with nothing lost.
  archived,

  /// Soft-deleted; recoverable until the retention window ends.
  deleted,
}

/// Inserts or updates a project after refusing malformed [settings] JSON.
Future<Result<Project>> upsertProject(
  GeneratedDatabase db, {
  required Insertable<Project> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    _ensureSettingsJson(row);
  } on Failure catch (failure) {
    return FailureResult<Project>(failure);
  }
  final AppDatabase database = db as AppDatabase;
  return _ProjectsDao(
    database,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).upsert(row);
}

/// A page of projects in [status], newest [Project.updatedAt] first.
///
/// The `WHERE status` plus `ORDER BY updated_at` shape is what
/// `projects_by_status` was created to serve.
Future<Result<List<Project>>> listProjectsByStatus(
  GeneratedDatabase db, {
  required ProjectStatus status,
  required int offset,
  required int limit,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<Project> rows =
        await (database.select(database.projects)
              ..where(($ProjectsTable tbl) => tbl.status.equalsValue(status))
              ..orderBy(<OrderClauseGenerator<$ProjectsTable>>[
                ($ProjectsTable tbl) => OrderingTerm.desc(tbl.updatedAt),
              ])
              ..limit(limit, offset: offset))
            .get();
    return Success<List<Project>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<Project>>(failure);
  } on Object catch (error) {
    return FailureResult<List<Project>>(storageFailureFrom(error));
  }
}

void _ensureSettingsJson(Insertable<Project> row) {
  final Expression<Object>? expression = row.toColumns(false)['settings'];
  if (expression is! Variable<String>) {
    return;
  }
  final String? settings = expression.value;
  if (settings == null) {
    return;
  }
  _parseProjectSettings(settings);
}

void _parseProjectSettings(String settings) {
  late final Object? decoded;
  try {
    decoded = jsonDecode(settings) as Object?;
  } on FormatException {
    throw const StorageFailure(
      message: 'Project settings are not valid JSON.',
      recoveryAction: 'Fix the settings object and save again.',
    );
  }
  if (decoded is! Map) {
    throw const StorageFailure(
      message: 'Project settings must be a JSON object.',
      recoveryAction: 'Fix the settings object and save again.',
    );
  }
}

final class _ProjectsDao extends BaseDao<Projects, Project> {
  _ProjectsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.projects);
}
