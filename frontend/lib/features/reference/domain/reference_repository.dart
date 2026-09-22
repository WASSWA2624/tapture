import 'dart:async';

import 'package:tapture/core/errors/result.dart';

import 'reference_dataset.dart';
import 'reference_row.dart';

export 'reference_dataset.dart';
export 'reference_row.dart';

/// Persistence port for imported reference tables. Drift types stop at the
/// data layer.
abstract interface class ReferenceRepository {
  /// Live list of every dataset on this device.
  Stream<List<ReferenceDataset>> watchAll();

  /// Live datasets visible to [projectId] (project-scoped plus global).
  Stream<List<ReferenceDataset>> watchByProject(String projectId);

  /// The dataset with [id], or null when it is not on this device.
  Future<Result<ReferenceDataset?>> byId(String id);

  /// Inserts or updates [dataset] and returns the stored header.
  Future<Result<ReferenceDataset>> save(ReferenceDataset dataset);

  /// Replaces [dataset]'s rows with [rows] in one write and returns the header.
  Future<Result<ReferenceDataset>> importDataset({
    required ReferenceDataset dataset,
    required List<ReferenceRow> rows,
  });

  /// Tombstones [id]. [reason] is required so a later audit can say why.
  Future<Result<void>> delete(String id, {required String reason});

  /// One page of rows for [datasetId], ordered by key.
  Future<Result<List<ReferenceRow>>> pageRows({
    required String datasetId,
    required int offset,
    required int limit,
    String query = '',
  });

  /// The row with [id], or null when missing.
  Future<Result<ReferenceRow?>> rowById(String id);

  /// Inserts or updates [row]. [previousValues] feeds the audit trail on edit.
  Future<Result<ReferenceRow>> saveRow(
    ReferenceRow row, {
    Map<String, String>? previousValues,
  });

  /// Indexed equality lookup on the key column.
  Future<Result<ReferenceRow?>> lookupByKey({
    required String datasetId,
    required String keyValue,
  });

  /// Indexed normalised lookup on the folded key.
  Future<Result<List<ReferenceRow>>> lookupByNormalised({
    required String datasetId,
    required String query,
  });

  /// Every row in [datasetId] for export. Prefer paging for UI.
  Future<Result<List<ReferenceRow>>> allRows(String datasetId);
}
