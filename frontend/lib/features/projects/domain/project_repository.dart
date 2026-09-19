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

  /// Writes a ready-to-capture project: the row, folder tree and default
  /// context, or a structural copy of [sourceId]. Row and folders succeed
  /// or fail together.
  Future<Result<Project>> createReady({
    required String name,
    String? description,
    String? organisation,
    String? sourceId,
  });

  /// Replaces the stored row that shares [Project.id].
  Future<Result<void>> update(Project project);

  /// Moves [id] to [status] without rewriting other fields.
  Future<Result<void>> setStatus(String id, ProjectStatus status);

  /// Active projects with record counts and last-worked time. One watch,
  /// not a query per row.
  Stream<List<ProjectListRow>> watchList();

  /// Pending Review, Process, Export and Share counts for [projectId].
  /// Derived from live watches, never stored (FE-STATE-06).
  Stream<ProjectHomeCounts> watchHome(String projectId);
}

/// One landing-list row: the project plus the counts and last-worked
/// instant the watch query returns. Named as a row so it is not an
/// `*Item` (FE-CODE-03).
typedef ProjectListRow = ({
  Project project,
  int recordCount,
  int unprocessedCount,
  DateTime lastWorkedAt,
});

/// Pending work on the open-project home. Named as counts so it is not
/// an `*Item` (FE-CODE-03).
typedef ProjectHomeCounts = ({
  int review,
  int process,
  int toExport,
  int toShare,
});

/// Empty home counts. Shared by the empty stand-in and tests.
const ProjectHomeCounts emptyProjectHomeCounts = (
  review: 0,
  process: 0,
  toExport: 0,
  toShare: 0,
);
