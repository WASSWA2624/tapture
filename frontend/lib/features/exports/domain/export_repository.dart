import 'dart:async';

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
}

/// One completed or in-progress export of a project.
typedef ExportEntry = ({
  String id,
  String projectId,
  int version,
  String status,
});
