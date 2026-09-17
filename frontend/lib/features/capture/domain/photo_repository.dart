import 'dart:async';

import 'package:tapture/core/errors/result.dart';

/// Persistence port for captured photographs. Drift types stop at the data
/// layer.
abstract interface class PhotoRepository {
  /// Live photos filed on [recordId], in stored order.
  Stream<List<PhotoAsset>> watchByRecord(String recordId);

  /// The photo with [id], or null when it is not on this device.
  Future<Result<PhotoAsset?>> byId(String id);

  /// Inserts or updates [photo] and returns the stored row.
  Future<Result<PhotoAsset>> save(PhotoAsset photo);

  /// Tombstones [id]. [reason] is required so a later audit can say why.
  Future<Result<void>> delete(String id, {required String reason});
}

/// A photograph kept as evidence on a record.
typedef PhotoAsset = ({
  String id,
  String projectId,
  String? recordId,
  String relativePath,
  String sha256,
});
