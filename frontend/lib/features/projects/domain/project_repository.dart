import 'dart:async';
import 'dart:typed_data';

import 'package:tapture/core/errors/result.dart';

import 'project.dart';
import 'project_settings.dart';
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

  /// Stores [bytes] as [projectId]'s photo: the file is written under
  /// `projects/<folder>/cover/` first, then the settings point at it. A
  /// replaced photo's file stays. Returns the new settings (D7).
  Future<Result<ProjectSettings>> setCoverPhoto(
    String projectId,
    Uint8List bytes,
  );

  /// Takes the photo off [projectId]; the file stays. Returns the new
  /// settings.
  Future<Result<ProjectSettings>> clearCoverPhoto(String projectId);

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

  /// Records on [projectId] whose status is one of [statuses], oldest first.
  Stream<List<ProjectRecordRow>> watchRecords(
    String projectId, {
    required List<String> statuses,
  });

  /// One live record with its photos, captions and audio, or null once it
  /// is archived, deleted or not on this device.
  Stream<ProjectRecordDetail?> watchRecord(String recordId);

  /// How many records on [projectId] use each template, counting records
  /// whose status is one of [statuses]. Keyed by template id.
  Stream<Map<String, int>> watchTemplateRecordCounts(
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

/// One field value on a captured record, for search and edit.
typedef ProjectRecordFieldValue = ({
  String fieldKey,
  String raw,
  String refined,
  String approved,
});

/// One stored photo, located for a thumbnail. [storagePath] is relative to
/// the storage root; [quarterTurns] is the saved rotation.
typedef RecordPhotoRef = ({
  String sha256,
  String storagePath,
  int quarterTurns,
});

/// One captured record shown on the project records list. [thumb] is the
/// record's first live photo, in its newest derived version.
typedef ProjectRecordRow = ({
  String id,
  String templateId,
  String status,
  int photoCount,
  RecordPhotoRef? thumb,
  List<ProjectRecordFieldValue> fields,
});

/// One photo on a record page, with its caption (`''` when none).
typedef RecordPhotoCaption = ({RecordPhotoRef photo, String caption});

/// One record as its page shows it. [caption] is the record caption, the
/// refined text when there is one; [photos] are the live photos in tray
/// order.
typedef ProjectRecordDetail = ({
  ProjectRecordRow row,
  String caption,
  List<RecordPhotoCaption> photos,
  int audioClips,
  DateTime capturedAt,
});

/// Records and files a project delete would hide. Named as counts so
/// it is not an `*Item` (FE-CODE-03).
typedef ProjectOwnedCounts = ({int records, int files});
