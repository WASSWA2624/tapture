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

  /// Pins or unpins [id] without rewriting other fields or bumping
  /// [Project.updatedAt].
  Future<Result<void>> setPinned(String id, bool pinned);

  /// Soft-deletes [id] and its owned rows, writes one tombstone per
  /// entity, then moves the project folder into the recycle area.
  Future<Result<void>> delete(String id);

  /// How many records and files a delete of [id] would hide.
  Future<Result<ProjectOwnedCounts>> ownedCounts(String id);

  /// Active projects with record counts and last-worked time. One watch,
  /// not a query per row. Archived rows appear only when requested.
  Stream<List<ProjectListRow>> watchList({bool includeArchived = false});

  /// Pending Review, Process, Export and Share counts for [projectId].
  /// Derived from live watches, never stored (FE-STATE-06).
  Stream<ProjectHomeCounts> watchHome(String projectId);

  /// Records on [projectId] whose status is one of [statuses], oldest first.
  Stream<List<ProjectRecordRow>> watchRecords(
    String projectId, {
    required List<String> statuses,
  });

  /// Hides [recordId] from lists. Photo files and raw values stay.
  Future<Result<void>> archiveRecord(String recordId);

  /// Writes a refined value beside the original raw column.
  Future<Result<void>> refineRecordField({
    required String recordId,
    required String fieldKey,
    required String value,
  });

  /// Stores the first value of a field [recordId] has no row for. The value
  /// is the typed original, exactly as capture stores a typed value, so it
  /// is written once and later edits refine it (FE-SEC-08).
  Future<Result<void>> addRecordField({
    required String recordId,
    required String fieldKey,
    required String value,
  });
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

/// One field value on a captured record, for search and edit.
typedef ProjectRecordFieldValue = ({
  String fieldKey,
  String raw,
  String refined,
  String approved,
});

/// One captured record shown on the project records list.
typedef ProjectRecordRow = ({
  String id,
  String templateId,
  String status,
  int photoCount,
  String? thumbPath,
  List<ProjectRecordFieldValue> fields,
});

/// Empty home counts. Shared by the empty stand-in and tests.
const ProjectHomeCounts emptyProjectHomeCounts = (
  review: 0,
  process: 0,
  toExport: 0,
  toShare: 0,
);

/// Records and files a project delete would hide. Named as counts so
/// it is not an `*Item` (FE-CODE-03).
typedef ProjectOwnedCounts = ({int records, int files});
