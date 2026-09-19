import 'dart:async';

import 'package:tapture/core/errors/result.dart';

import 'project.dart';
import 'project_status.dart';

export 'project.dart';
export 'project_settings.dart';
export 'project_status.dart';

/// Persistence port for field projects. Drift types stop at the data layer.
abstract interface class ProjectRepository {
  /// Live list of projects. Archived rows are omitted unless requested.
  Stream<List<Project>> watchAll({bool includeArchived = false});

  /// Inserts [project] and returns the stored row.
  Future<Result<Project>> create(Project project);

  /// Replaces the stored row that shares [Project.id].
  Future<Result<void>> update(Project project);

  /// Moves [id] to [status] without rewriting other fields.
  Future<Result<void>> setStatus(String id, ProjectStatus status);
}
