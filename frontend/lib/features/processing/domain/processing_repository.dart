import 'dart:async';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/localized_message.dart';
import 'package:tapture/core/errors/result.dart';

import 'processing_job.dart';
import 'queue_failure_page.dart';

export 'job_queue.dart';
export 'processing_job.dart';
export 'queue_failure_page.dart';

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

  /// Live summary counts and groups, without materializing failed jobs.
  Stream<QueueSnapshot> watchQueue({String? projectId});

  /// One live oldest-first page. Tombstoned jobs and records are excluded
  /// before the limit; [after] survives its row being retried or deleted.
  Stream<QueueFailurePage> watchFailurePage({
    String? projectId,
    QueueFailureCursor? after,
    int limit = AppConstants.listPageSize,
  });

  /// Queues captured records that do not yet have a job.
  ///
  /// [groupLabels] use the same context labels the queue screen shows. Empty
  /// means every group.
  Future<Result<int>> enqueuePending({
    String? projectId,
    List<String> groupLabels = const <String>[],
  });

  /// Queues [recordId] once and returns the persisted job id.
  Future<Result<String>> enqueue(String recordId);

  /// Queues [recordId] to be processed again from the first stage and
  /// returns its job id.
  ///
  /// The record's existing job is reset (stage cleared, queued, attempts 0,
  /// lease, error and timestamps cleared), or a job is created when it has
  /// none. A record in draft, captured, extracted, needs review, approved or
  /// failed moves to queued, with an audited status change; one already
  /// queued keeps its status. A record that is processing, archived or
  /// deleted, or whose job a runner holds now, fails with a
  /// `ValidationFailure` and nothing is written.
  Future<Result<String>> requeue(String recordId);

  /// Claims the oldest ready job in [projectId] and [groupLabels] (empty
  /// for every group), releasing expired leases first. Returns null while
  /// the running jobs already hold the settings-store concurrency cap.
  ///
  /// With [unfinished], only a job that has not yet completed that stage is
  /// claimed, so a run that stops after it never takes the same job twice.
  /// A job in [skip] is passed over, so a batch can set one aside and carry
  /// on with the rest.
  Future<Result<ProcessingJob?>> claim(
    Duration lease, {
    String? projectId,
    List<String> groupLabels = const <String>[],
    JobStage? unfinished,
    Set<String> skip = const <String>{},
  });

  /// Marks [jobId] complete in one transaction.
  Future<Result<void>> complete(String jobId);

  /// Records [reason] and either schedules a retry or stops permanently.
  Future<Result<void>> fail(
    String jobId,
    String reason, {
    required bool permanent,
    LocalizedMessage? localizedReason,
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
);
