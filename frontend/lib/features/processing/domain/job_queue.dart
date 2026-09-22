import 'processing_job.dart';

/// Leases a job to exactly one runner and takes it back after a crash.
///
/// Enqueue, claim, complete and fail each commit in one transaction.
abstract interface class JobQueue {
  /// Queues [recordId] and returns the job id. A second call returns the
  /// job already waiting for that record.
  Future<String> enqueue(String recordId);

  /// Claims the oldest ready job for [lease], or null when none is free.
  ///
  /// An expired lease is released inside the same transaction, so a job
  /// killed mid-run becomes claimable again. The concurrency cap is read
  /// from the settings store by the implementation.
  Future<ProcessingJob?> claim(Duration lease);

  /// Marks [jobId] finished.
  Future<void> complete(String jobId);

  /// Records [reason] on [jobId]. A permanent failure stops. A transient
  /// one returns to the queue after bounded backoff.
  Future<void> fail(String jobId, String reason, {required bool permanent});
}
