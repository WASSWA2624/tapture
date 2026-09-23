import 'dart:async';

import 'package:tapture/core/errors/result.dart';

import 'processing_job.dart';

export 'job_queue.dart';
export 'processing_job.dart';

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

  /// Counts and groups from queries, plus the failed jobs.
  Stream<QueueSnapshot> watchQueue({String? projectId});

  /// Queues captured records that do not yet have a job.
  ///
  /// [groupLabel] uses the same context label shown by the queue screen.
  Future<Result<int>> enqueuePending({String? projectId, String? groupLabel});

  /// Queues [recordId] once and returns the persisted job id.
  Future<Result<String>> enqueue(String recordId);

  /// Claims the oldest ready job, releasing expired leases first.
  Future<Result<ProcessingJob?>> claim(
    Duration lease, {
    String? projectId,
    String? groupLabel,
  });

  /// Marks [jobId] complete in one transaction.
  Future<Result<void>> complete(String jobId);

  /// Records [reason] and either schedules a retry or stops permanently.
  Future<Result<void>> fail(
    String jobId,
    String reason, {
    required bool permanent,
  });

  /// Records [stage] as the last completed stage.
  Future<Result<ProcessingJob>> markStage(String id, JobStage stage);

  /// Returns a running job to the queue without losing completed stages.
  Future<Result<void>> release(String id);

  /// Returns a stopped job to the queue after an explicit operator retry.
  Future<Result<void>> retry(String id);

  /// Requests and images stored since the start of [day].
  Future<Result<({int requests, int images})>> usageOn(
    DateTime day, {
    String? projectId,
  });
}

/// One context group on the queue.
typedef QueueGroup = ({String label, int records});

/// Counts and groups the queue screen draws. The jobs themselves are not
/// materialised to produce the counts.
typedef QueueSnapshot = ({
  int unprocessed,
  int queued,
  int failed,
  int requestsToday,
  int imagesToday,
  int requestCap,
  List<QueueGroup> groups,
  List<ProcessingJob> failures,
});

/// An empty snapshot.
const QueueSnapshot emptyQueueSnapshot = (
  unprocessed: 0,
  queued: 0,
  failed: 0,
  requestsToday: 0,
  imagesToday: 0,
  requestCap: 0,
  groups: <QueueGroup>[],
  failures: <ProcessingJob>[],
);
