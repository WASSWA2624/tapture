import 'dart:async';

import 'package:tapture/core/errors/result.dart';

import 'job_queue.dart';
import 'processing_job.dart';

export 'job_queue.dart';
export 'processing_job.dart';

/// Persistence port for processing jobs. Drift types stop at the data layer.
abstract interface class ProcessingRepository implements JobQueue {
  /// Live list of jobs on this device.
  Stream<List<ProcessingJob>> watchAll();

  /// The job with [id], or null when it is not on this device.
  Future<Result<ProcessingJob?>> byId(String id);

  /// Inserts or updates [job] and returns the stored row.
  Future<Result<ProcessingJob>> save(ProcessingJob job);

  /// Tombstones [id]. [reason] is required so a later audit can say why.
  Future<Result<void>> delete(String id, {required String reason});

  /// Counts and groups from queries, plus the failed jobs.
  Stream<QueueSnapshot> watchQueue();

  /// Records [stage] as the last completed stage.
  Future<Result<ProcessingJob>> markStage(String id, JobStage stage);

  /// Returns a running job to the queue without losing completed stages.
  Future<Result<void>> release(String id);

  /// Requests and images stored since the start of [day].
  Future<Result<({int requests, int images})>> usageOn(DateTime day);
}

/// One context group on the queue.
typedef QueueGroup = ({String label, int records});

/// Counts and groups the queue screen draws. The jobs themselves are not
/// materialised to produce the counts.
typedef QueueSnapshot = ({
  int unprocessed,
  int queued,
  int failed,
  List<QueueGroup> groups,
  List<ProcessingJob> failures,
});

/// An empty snapshot.
const QueueSnapshot emptyQueueSnapshot = (
  unprocessed: 0,
  queued: 0,
  failed: 0,
  groups: <QueueGroup>[],
  failures: <ProcessingJob>[],
);
