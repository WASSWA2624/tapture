/// One unit of on-device or online processing for a single record.
///
/// [stage] is the last stage marked complete. A resume skips every stage up
/// to and including that one. [status] is the queue lifecycle.
final class ProcessingJob {
  /// Creates a job. [id] is empty until the queue assigns one.
  const ProcessingJob({
    required this.id,
    required this.recordId,
    this.stage = '',
    this.attemptCount = 0,
    this.status = JobStatus.queued,
    this.lastError,
    this.leaseExpiresAt,
    this.permanent = false,
    this.skipReason,
    this.rejections = const <String>[],
    this.provider,
    this.model,
    this.queuedAt,
    this.startedAt,
    this.finishedAt,
  });

  /// Merge identity.
  final String id;

  /// Record this job processes.
  final String recordId;

  /// Last completed [JobStage] name, or empty when none has finished.
  final String stage;

  /// How many attempts have been spent, including the one in progress.
  final int attemptCount;

  /// queued, running, completed or failed.
  final JobStatus status;

  /// Failure or cap message, shown verbatim on the queue.
  final String? lastError;

  /// When the current claim stops being owned by its runner.
  final DateTime? leaseExpiresAt;

  /// A permanent failure is not retried.
  final bool permanent;

  /// Why the online stage was skipped, when it was.
  final String? skipReason;

  /// Why a proposed value was dropped.
  final List<String> rejections;

  /// Provider name, when an online stage ran.
  final String? provider;

  /// Model name, when an online stage ran.
  final String? model;

  /// When the job entered the queue.
  final DateTime? queuedAt;

  /// When it was claimed, or the instant a retry may be claimed again.
  final DateTime? startedAt;

  /// When it last finished.
  final DateTime? finishedAt;

  /// Stages already marked complete, derived from [stage].
  Set<JobStage> get completedStages {
    final JobStage? last = lastCompleted;
    if (last == null) {
      return const <JobStage>{};
    }
    final int index = JobStage.values.indexOf(last);
    return JobStage.values.take(index + 1).toSet();
  }

  /// The last stage whose work must not be repeated, or null.
  JobStage? get lastCompleted {
    for (final JobStage value in JobStage.values) {
      if (value.name == stage) {
        return value;
      }
    }
    return null;
  }

  /// A copy with the provided fields replaced.
  ///
  /// Pass [clearError], [clearLease] or [clearSkip] to store null.
  ProcessingJob copyWith({
    String? id,
    String? recordId,
    String? stage,
    int? attemptCount,
    JobStatus? status,
    String? lastError,
    bool clearError = false,
    DateTime? leaseExpiresAt,
    bool clearLease = false,
    bool? permanent,
    String? skipReason,
    bool clearSkip = false,
    List<String>? rejections,
    String? provider,
    String? model,
    DateTime? queuedAt,
    DateTime? startedAt,
    bool clearStarted = false,
    DateTime? finishedAt,
    bool clearFinished = false,
  }) {
    return ProcessingJob(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      stage: stage ?? this.stage,
      attemptCount: attemptCount ?? this.attemptCount,
      status: status ?? this.status,
      lastError: clearError ? null : (lastError ?? this.lastError),
      leaseExpiresAt: clearLease
          ? null
          : (leaseExpiresAt ?? this.leaseExpiresAt),
      permanent: permanent ?? this.permanent,
      skipReason: clearSkip ? null : (skipReason ?? this.skipReason),
      rejections: rejections ?? this.rejections,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      queuedAt: queuedAt ?? this.queuedAt,
      startedAt: clearStarted ? null : (startedAt ?? this.startedAt),
      finishedAt: clearFinished ? null : (finishedAt ?? this.finishedAt),
    );
  }
}

/// Stages a job walks, in order.
enum JobStage {
  /// Resize, orientation, deskew, contrast and document bounds.
  prepare,

  /// On-device text, blocks and identifiers.
  onDevice,

  /// Template selection.
  detect,

  /// Optional online extraction.
  online,

  /// Units, choices, dates and row matching.
  normalise,

  /// Schema, evidence and proposal writes.
  validate,
}

/// Lifecycle of a [ProcessingJob].
enum JobStatus {
  /// Waiting to be claimed.
  queued,

  /// Owned by one runner until [ProcessingJob.leaseExpiresAt].
  running,

  /// Finished successfully.
  completed,

  /// Stopped. A transient failure returns to [queued] instead.
  failed,
}
