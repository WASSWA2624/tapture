import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/projects.dart' as projects_db;

import '../domain/project.dart';
import '../domain/project_settings.dart';
import '../domain/project_status.dart';

/// Maps a Drift project row onto the domain [Project] and back.
///
/// Presentation never sees a database type; only
/// [ProjectRepositoryImpl] and this mapper import both layers.
abstract final class ProjectMapper {
  /// Reads a stored row. Unknown or missing settings JSON become
  /// [ProjectSettings.defaults]; [Project.description] is lifted out of
  /// the settings object because the table has no description column.
  static Project fromRow(sqlite.Project row) {
    final Object? decoded = _tryDecode(row.settings);
    return Project(
      id: row.id,
      name: row.name,
      status: statusFromRow(row.status),
      folderName: row.folderName,
      settings: ProjectSettings.fromJson(decoded),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      description: _descriptionOf(decoded),
      organisation: _optionalText(row.client),
      startsOn: row.startedAt,
      endsOn: row.completedAt,
      pinnedAt: row.pinnedAt,
    );
  }

  /// Writes [project] as an insertable row. [Project.folderName] is
  /// passed through unchanged. [Project.description] is stored inside
  /// the settings JSON; [Project.organisation] maps onto `client`.
  static sqlite.ProjectsCompanion toRow(Project project) {
    return sqlite.ProjectsCompanion(
      id: project.id.isEmpty
          ? const Value<String>.absent()
          : Value<String>(project.id),
      name: Value<String>(project.name),
      client: Value<String>(project.organisation?.trim() ?? ''),
      status: Value<projects_db.ProjectStatus>(statusToRow(project.status)),
      startedAt: Value<DateTime?>(project.startsOn),
      completedAt: Value<DateTime?>(project.endsOn),
      folderName: Value<String>(project.folderName),
      settings: Value<String>(_encodeSettings(project)),
      pinnedAt: Value<DateTime?>(project.pinnedAt),
    );
  }

  /// Domain status for a stored enum value.
  static ProjectStatus statusFromRow(projects_db.ProjectStatus status) {
    return switch (status) {
      projects_db.ProjectStatus.active => ProjectStatus.active,
      projects_db.ProjectStatus.archived => ProjectStatus.archived,
      projects_db.ProjectStatus.deleted => ProjectStatus.deleted,
    };
  }

  /// Stored enum value for a domain status.
  static projects_db.ProjectStatus statusToRow(ProjectStatus status) {
    return switch (status) {
      ProjectStatus.active => projects_db.ProjectStatus.active,
      ProjectStatus.archived => projects_db.ProjectStatus.archived,
      ProjectStatus.deleted => projects_db.ProjectStatus.deleted,
    };
  }
}

const String _descriptionKey = 'description';

Object? _tryDecode(String raw) {
  if (raw.trim().isEmpty) {
    return null;
  }
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

String? _descriptionOf(Object? decoded) {
  if (decoded is! Map) {
    return null;
  }
  return _optionalText(decoded[_descriptionKey]);
}

String _encodeSettings(Project project) {
  final Map<String, Object?> json = project.settings.toJson();
  final String? description = _optionalText(project.description);
  if (description == null) {
    json.remove(_descriptionKey);
  } else {
    json[_descriptionKey] = description;
  }
  return jsonEncode(json);
}

String? _optionalText(Object? raw) {
  if (raw is String && raw.trim().isNotEmpty) {
    return raw.trim();
  }
  return null;
}
