import 'processing_job.dart';

/// Walks [JobStage] in order, persisting each one before the next starts.
///
/// A cancel between stages leaves the record untouched and the job resumable
/// from the next stage. A resumed job skips stages already on [ProcessingJob.stage].
final class JobRunner {
  /// Creates a runner. [perform] does one stage. [persist] stores it before
  /// the next stage starts. [release] returns a cancelled job to the queue.
  const JobRunner({
    required this.perform,
    required this.persist,
    required this.release,
  });

  /// Runs [stage] for [job]. Throw to fail the stage.
  final Future<void> Function(JobStage stage, ProcessingJob job) perform;

  /// Stores [stage] as complete and returns the job to continue with.
  final Future<ProcessingJob> Function(ProcessingJob job, JobStage stage)
  persist;

  /// Puts [job] back without losing completed stages.
  final Future<ProcessingJob> Function(ProcessingJob job) release;

  /// The order every job walks.
  static const List<JobStage> order = <JobStage>[
    JobStage.prepare,
    JobStage.onDevice,
    JobStage.detect,
    JobStage.online,
    JobStage.normalise,
    JobStage.validate,
  ];

  /// Runs [job] until it finishes, [isCancelled] flips, or [perform] throws.
  Future<JobRun> run(
    ProcessingJob job, {
    required bool Function() isCancelled,
  }) async {
    final Set<JobStage> done = job.completedStages;
    ProcessingJob current = job;
    for (final JobStage stage in order) {
      if (isCancelled()) {
        final ProcessingJob released = await release(current);
        return (job: released, cancelled: true);
      }
      if (done.contains(stage) || current.completedStages.contains(stage)) {
        continue;
      }
      await perform(stage, current);
      current = await persist(current, stage);
    }
    return (job: current, cancelled: false);
  }
}

/// Outcome of one [JobRunner.run].
typedef JobRun = ({ProcessingJob job, bool cancelled});
