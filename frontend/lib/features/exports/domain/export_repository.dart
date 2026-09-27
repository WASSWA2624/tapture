import 'dart:async';

import 'package:tapture/core/bundle/bundle_output.dart';
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

  /// Writes one new project package for [projectId]: every table and file
  /// another Tapture app needs to open the project, with the workbook inside
  /// as `records.xlsx` (task 076, D13). The file is stored before the row.
  /// [cancel] drops a partial file and writes no row; [onProgress] reports
  /// the share written, 0 to 1.
  Future<Result<ExportedPackage>> exportProject(
    String projectId, {
    required CancellationToken cancel,
    void Function(double)? onProgress,
  });

  /// Bytes the package of [projectId] is expected to take, shown before the
  /// export starts.
  Future<Result<int>> estimatePackage(String projectId);

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

/// A project package written on this device: a stored file on a device, or
/// bytes in a browser. It is shared only after the operator asks.
typedef ExportedPackage = ({
  String id,
  String projectId,
  int version,
  String fileName,
  BundleOutput package,
});
