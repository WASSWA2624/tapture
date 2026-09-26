import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/processing.dart' as jobs;
import 'package:tapture/features/processing/data/processing_job_mapper.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

void main() {
  late AppDatabase db;
  final DateTime queuedAt = DateTime.utc(2026, 9, 26, 8);

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<ProcessingJobRow> roundTrip(ProcessingJob job) async {
    await db
        .into(db.processing)
        .insert(
          ProcessingJobMapper.toCompanion(job, queuedAt: queuedAt).copyWith(
            createdAt: Value<DateTime>(queuedAt),
            updatedAt: Value<DateTime>(queuedAt),
            updatedByDevice: const Value<String>('device-a'),
            rev: const Value<int>(1),
          ),
        );
    return (db.select(
      db.processing,
    )..where(($ProcessingTable t) => t.id.equals(job.id))).getSingle();
  }

  test('a job survives the round trip through its row', () async {
    const ProcessingJob job = ProcessingJob(
      id: 'job-1',
      recordId: 'record-1',
      stage: 'detect',
      attemptCount: 2,
      status: JobStatus.queued,
      lastError: 'Timed out.',
      skipReason: 'Offline mode is on.',
      rejections: <String>['No evidence supports model.'],
      provider: 'backend',
      model: 'default',
    );

    final ProcessingJob read = ProcessingJobMapper.toJob(await roundTrip(job));

    expect(read.id, 'job-1');
    expect(read.recordId, 'record-1');
    expect(read.stage, 'detect');
    expect(read.attemptCount, 2);
    expect(read.status, JobStatus.queued);
    expect(read.lastError, 'Timed out.');
    expect(read.skipReason, 'Offline mode is on.');
    expect(read.rejections, <String>['No evidence supports model.']);
    expect(read.provider, 'backend');
    expect(read.queuedAt?.toUtc(), queuedAt, reason: 'the stand-in is used');
    expect(read.permanent, isFalse);
  });

  test('every status maps both ways, and a failed row is permanent', () async {
    for (final JobStatus status in JobStatus.values) {
      expect(
        ProcessingJobMapper.jobStatus(ProcessingJobMapper.rowStatus(status)),
        status,
      );
    }
    final ProcessingJob failed = ProcessingJobMapper.toJob(
      await roundTrip(
        const ProcessingJob(
          id: 'job-2',
          recordId: 'record-1',
          status: JobStatus.failed,
        ),
      ),
    );
    expect(failed.permanent, isTrue);
    expect(
      ProcessingJobMapper.rowStatus(JobStatus.running),
      jobs.ProcessingJobStatus.running,
    );
  });

  test('no rejections store as null and bad JSON reads as none', () async {
    final ProcessingJobRow row = await roundTrip(
      const ProcessingJob(id: 'job-3', recordId: 'record-1'),
    );
    expect(row.rejections, isNull);

    await (db.update(db.processing)
          ..where(($ProcessingTable t) => t.id.equals('job-3')))
        .write(const ProcessingCompanion(rejections: Value<String?>('{oops')));
    final ProcessingJobRow broken = await (db.select(
      db.processing,
    )..where(($ProcessingTable t) => t.id.equals('job-3'))).getSingle();
    expect(ProcessingJobMapper.toJob(broken).rejections, isEmpty);
  });
}
