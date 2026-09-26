import 'package:tapture/core/concurrency/cancellation_token.dart';

import 'processing_job.dart';

/// Walks [JobStage.values] in order, persisting each stage before the next
/// starts.
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

  /// Runs [stage] for [job]. Throw to fail the stage. The token is the one
  /// [run] was given, so stage work can stop early too.
  final Future<void> Function(
    JobStage stage,
    ProcessingJob job,
    CancellationToken token,
  )
  perform;

  /// Stores [stage] as complete and returns the job to continue with.
  final Future<ProcessingJob> Function(ProcessingJob job, JobStage stage)
  persist;

  /// Puts [job] back without losing completed stages.
  final Future<ProcessingJob> Function(ProcessingJob job) release;

  /// Runs [job] until it finishes, [token] is cancelled, or [perform] throws.
  ///
  /// With [stopAfter], the run ends once that stage is complete and the job
  /// is released for a later run to finish, as opportunistic on-device
  /// reading does before any online stage.
  Future<JobRun> run(
    ProcessingJob job, {
    required CancellationToken token,
    JobStage? stopAfter,
  }) async {
    ProcessingJob current = job;
    for (final JobStage stage in JobStage.values) {
      if (token.isCancelled) {
        final ProcessingJob released = await release(current);
        return (job: released, cancelled: true, paused: false);
      }
      if (!current.completedStages.contains(stage)) {
        await perform(stage, current, token);
        current = await persist(current, stage);
      }
      if (stage == stopAfter && stage != JobStage.values.last) {
        final ProcessingJob released = await release(current);
        return (job: released, cancelled: false, paused: true);
      }
    }
    return (job: current, cancelled: false, paused: false);
  }
}

/// Outcome of one [JobRunner.run]. [paused] means the run stopped at its
/// `stopAfter` stage and the job waits for the rest.
typedef JobRun = ({ProcessingJob job, bool cancelled, bool paused});
