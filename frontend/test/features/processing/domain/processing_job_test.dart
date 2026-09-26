import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

void main() {
  test('stages run in the Contract order', () {
    expect(JobStage.values, <JobStage>[
      JobStage.prepare,
      JobStage.onDevice,
      JobStage.detect,
      JobStage.online,
      JobStage.normalise,
      JobStage.validate,
    ]);
  });

  test('completed stages are every stage up to the last one stored', () {
    const ProcessingJob fresh = ProcessingJob(id: 'j', recordId: 'r');
    expect(fresh.lastCompleted, isNull);
    expect(fresh.completedStages, isEmpty);

    const ProcessingJob read = ProcessingJob(
      id: 'j',
      recordId: 'r',
      stage: 'detect',
    );
    expect(read.lastCompleted, JobStage.detect);
    expect(read.completedStages, <JobStage>{
      JobStage.prepare,
      JobStage.onDevice,
      JobStage.detect,
    });
  });

  test('an unknown stage name completes nothing', () {
    const ProcessingJob odd = ProcessingJob(
      id: 'j',
      recordId: 'r',
      stage: 'renamed',
    );
    expect(odd.lastCompleted, isNull);
    expect(odd.completedStages, isEmpty);
  });

  test('copyWith replaces fields and the clear flags store null', () {
    final DateTime at = DateTime.utc(2026, 9, 26, 8);
    final ProcessingJob job = ProcessingJob(
      id: 'j',
      recordId: 'r',
      lastError: 'Offline.',
      leaseExpiresAt: at,
      skipReason: 'Local match.',
      startedAt: at,
      finishedAt: at,
    );
    final ProcessingJob next = job.copyWith(
      status: JobStatus.running,
      attemptCount: 2,
      rejections: const <String>['No evidence supports serial.'],
    );
    expect(next.status, JobStatus.running);
    expect(next.attemptCount, 2);
    expect(next.rejections, hasLength(1));
    expect(next.lastError, 'Offline.');

    final ProcessingJob cleared = job.copyWith(
      clearError: true,
      clearLease: true,
      clearSkip: true,
      clearStarted: true,
      clearFinished: true,
    );
    expect(cleared.lastError, isNull);
    expect(cleared.leaseExpiresAt, isNull);
    expect(cleared.skipReason, isNull);
    expect(cleared.startedAt, isNull);
    expect(cleared.finishedAt, isNull);
    expect(cleared.recordId, 'r');
  });
}
