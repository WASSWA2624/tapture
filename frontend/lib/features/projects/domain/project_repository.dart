import 'dart:async';

import 'package:tapture/core/errors/result.dart';

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

/// Lifecycle of a [Project].
enum ProjectStatus {
  /// Open for capture and listed by default.
  active,

  /// Hidden from the default list; reversible with nothing lost.
  archived,

  /// Soft-deleted; recoverable until the retention window ends.
  deleted,
}

/// Identity, listing status and on-disk folder of a field project.
typedef Project = ({
  String id,
  String name,
  ProjectStatus status,
  String folderName,
});
