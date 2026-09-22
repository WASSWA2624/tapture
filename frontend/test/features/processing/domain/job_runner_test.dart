import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/job_runner.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

void main() {
  test('stages run in order and a resume skips completed ones', () async {
    final List<JobStage> ran = <JobStage>[];
    final JobRunner runner = JobRunner(
      perform: (JobStage stage, ProcessingJob job) async {
        ran.add(stage);
      },
      persist: (ProcessingJob job, JobStage stage) async {
        return job.copyWith(stage: stage.name);
      },
      release: (ProcessingJob job) async => job,
    );
    final JobRun first = await runner.run(
      const ProcessingJob(id: 'j', recordId: 'r', stage: 'onDevice'),
      isCancelled: () => false,
    );
    expect(ran, <JobStage>[
      JobStage.detect,
      JobStage.online,
      JobStage.normalise,
      JobStage.validate,
    ]);
    expect(first.job.stage, 'validate');
    expect(first.cancelled, isFalse);
  });

  test('cancel between stages keeps the job resumable', () async {
    var steps = 0;
    final JobRunner runner = JobRunner(
      perform: (JobStage stage, ProcessingJob job) async {},
      persist: (ProcessingJob job, JobStage stage) async {
        return job.copyWith(stage: stage.name, status: JobStatus.running);
      },
      release: (ProcessingJob job) async {
        return job.copyWith(status: JobStatus.queued);
      },
    );
    final JobRun run = await runner.run(
      const ProcessingJob(id: 'j', recordId: 'r'),
      isCancelled: () {
        steps++;
        return steps > 1;
      },
    );
    expect(run.cancelled, isTrue);
    expect(run.job.status, JobStatus.queued);
    expect(run.job.stage, 'prepare');
    expect(run.job.recordId, 'r');
  });
}
