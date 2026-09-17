import 'dart:async';

import 'package:tapture/core/errors/result.dart';

/// Persistence port for processing jobs. Drift types stop at the data layer.
abstract interface class ProcessingRepository {
  /// Live list of jobs on this device.
  Stream<List<ProcessingJob>> watchAll();

  /// The job with [id], or null when it is not on this device.
  Future<Result<ProcessingJob?>> byId(String id);

  /// Inserts or updates [job] and returns the stored row.
  Future<Result<ProcessingJob>> save(ProcessingJob job);

  /// Tombstones [id]. [reason] is required so a later audit can say why.
  Future<Result<void>> delete(String id, {required String reason});
}

/// One unit of on-device or online processing work.
typedef ProcessingJob = ({
  String id,
  String recordId,
  String stage,
  int attemptCount,
});
