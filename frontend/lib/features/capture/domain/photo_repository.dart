import 'dart:async';

import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';

/// Persistence port for captured photographs. Drift types stop at the data
/// layer.
abstract interface class PhotoRepository {
  /// Independently deleted photos under a live project and record.
  Stream<List<DeletedEntity>> watchDeleted();

  /// Lifts this photo's tombstone after checking its parent and durable bytes.
  Future<Result<void>> restore(String id);

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
