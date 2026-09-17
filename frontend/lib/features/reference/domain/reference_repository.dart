import 'dart:async';

import 'package:tapture/core/errors/result.dart';

/// Persistence port for imported reference tables. Drift types stop at the
/// data layer.
abstract interface class ReferenceRepository {
  /// Live list of datasets on this device.
  Stream<List<ReferenceDataset>> watchAll();

  /// The dataset with [id], or null when it is not on this device.
  Future<Result<ReferenceDataset?>> byId(String id);

  /// Inserts or updates [dataset] and returns the stored row.
  Future<Result<ReferenceDataset>> save(ReferenceDataset dataset);

  /// Tombstones [id]. [reason] is required so a later audit can say why.
  Future<Result<void>> delete(String id, {required String reason});
}

/// An imported table used to prefill a record.
typedef ReferenceDataset = ({
  String id,
  String name,
  String keyColumn,
  int rowCount,
});
