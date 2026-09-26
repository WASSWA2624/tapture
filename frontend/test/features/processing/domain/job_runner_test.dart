import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/features/processing/domain/job_runner.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

void main() {
  test('stages run in order and a resume skips completed ones', () async {
    final List<JobStage> ran = <JobStage>[];
    final JobRunner runner = JobRunner(
      perform: (JobStage stage, ProcessingJob job, CancellationToken _) async {
        ran.add(stage);
      },
      persist: (ProcessingJob job, JobStage stage) async {
        return job.copyWith(stage: stage.name);
      },
      release: (ProcessingJob job) async => job,
    );
    final JobRun first = await runner.run(
      const ProcessingJob(id: 'j', recordId: 'r', stage: 'onDevice'),
      token: CancellationToken(),
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

  test('a fresh job runs every stage in the Contract order', () async {
    final List<JobStage> ran = <JobStage>[];
    final JobRunner runner = JobRunner(
      perform: (JobStage stage, ProcessingJob job, CancellationToken _) async {
        ran.add(stage);
      },
      persist: (ProcessingJob job, JobStage stage) async {
        return job.copyWith(stage: stage.name);
      },
      release: (ProcessingJob job) async => job,
    );
    await runner.run(
      const ProcessingJob(id: 'j', recordId: 'r'),
      token: CancellationToken(),
    );
    expect(ran, JobStage.values);
  });

  test('cancel between stages keeps the job resumable', () async {
    final CancellationToken token = CancellationToken();
    final List<JobStage> ran = <JobStage>[];
    final JobRunner runner = JobRunner(
      perform:
          (JobStage stage, ProcessingJob job, CancellationToken given) async {
            expect(given, same(token));
            ran.add(stage);
            // The operator cancels while the first stage is running.
            token.cancel();
          },
      persist: (ProcessingJob job, JobStage stage) async {
        return job.copyWith(stage: stage.name, status: JobStatus.running);
      },
      release: (ProcessingJob job) async {
        return job.copyWith(status: JobStatus.queued);
      },
    );
    final JobRun run = await runner.run(
      const ProcessingJob(id: 'j', recordId: 'r'),
      token: token,
    );
    expect(ran, <JobStage>[JobStage.prepare]);
    expect(run.cancelled, isTrue);
    expect(run.job.status, JobStatus.queued);
    expect(run.job.stage, 'prepare');
    expect(run.job.recordId, 'r');
  });

  test('a token cancelled before the run starts runs nothing', () async {
    final CancellationToken token = CancellationToken()..cancel();
    var ran = 0;
    final JobRunner runner = JobRunner(
      perform: (JobStage _, ProcessingJob _, CancellationToken _) async {
        ran++;
      },
      persist: (ProcessingJob job, JobStage stage) async => job,
      release: (ProcessingJob job) async => job,
    );
    final JobRun run = await runner.run(
      const ProcessingJob(id: 'j', recordId: 'r'),
      token: token,
    );
    expect(ran, 0);
    expect(run.cancelled, isTrue);
  });
}
