import 'dart:async';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';

/// Persistence port for completed exports. Drift types stop at the data layer.
abstract interface class ExportRepository {
  /// Live export history for [projectId], newest first as stored.
  Stream<List<ExportEntry>> watchByProject(String projectId);

  /// The export with [id], or null when it is not on this device.
  Future<Result<ExportEntry?>> byId(String id);

  /// Inserts or updates [entry] and returns the stored row.
  Future<Result<ExportEntry>> save(ExportEntry entry);

  /// Tombstones [id]. [reason] is required so a later audit can say why.
  Future<Result<void>> delete(String id, {required String reason});

  /// Writes one new workbook for [projectId]. The file is stored before the
  /// row. [cancel] drops a partial file and writes no row.
  Future<Result<ExportedWorkbook>> exportProject(
    String projectId, {
    required CancellationToken cancel,
  });

  /// What an export of [projectId] would hold: the records [exportProject]
  /// writes, with their photos, audio, statuses, templates and dates.
  Stream<ExportSummary> watchSummary(String projectId);
}

/// Records written with one template, by the template's stored name.
typedef ExportTemplateCount = ({String name, int records});

/// The project an export would write. [records] is the workbook's row count.
typedef ExportSummary = ({
  String projectName,
  int records,
  int photos,
  int audioClips,
  int unprocessed,
  int needsReview,
  int approved,
  List<ExportTemplateCount> templates,
  DateTime? firstCapturedAt,
  DateTime? lastCapturedAt,
});

/// A summary of a project with nothing to export.
const ExportSummary emptyExportSummary = (
  projectName: '',
  records: 0,
  photos: 0,
  audioClips: 0,
  unprocessed: 0,
  needsReview: 0,
  approved: 0,
  templates: <ExportTemplateCount>[],
  firstCapturedAt: null,
  lastCapturedAt: null,
);

/// One completed or in-progress export of a project.
typedef ExportEntry = ({
  String id,
  String projectId,
  int version,
  String status,
});

/// A workbook stored on this device. [bytes] are shared only after the
/// operator asks.
typedef ExportedWorkbook = ({
  String id,
  String projectId,
  int version,
  String fileName,
  Uint8List bytes,
});
