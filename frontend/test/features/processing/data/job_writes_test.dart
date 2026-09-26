import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/data/job_writes.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

void main() {
  late AppDatabase db;
  late ProcessingRepositoryImpl repository;
  late JobWrites writes;
  final DateTime t0 = DateTime.utc(2026, 9, 23, 8);

  setUp(() {
    db = AppDatabase.memory();
    final FixedClock clock = FixedClock(t0);
    repository = ProcessingRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
      settings: SettingsStore.fake(),
    );
    writes = JobWrites(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<ProcessingJob> stored(String id) async {
    return (await repository.byId(
      id,
    )).fold((Failure failure) => throw failure, (ProcessingJob? job) => job!);
  }

  test('the skip reason and the provider land on the job', () async {
    final String id = _ok(await repository.enqueue('record-1'));

    await writes.setSkip(id, 'Filled locally.');
    await writes.setProvider(id, provider: 'backend', model: 'default');

    final ProcessingJob job = await stored(id);
    expect(job.skipReason, 'Filled locally.');
    expect(job.provider, 'backend');
    expect(job.model, 'default');
  });

  test('a queue message puts a claimed job back on the queue', () async {
    final String id = _ok(await repository.enqueue('record-1'));
    _ok(await repository.claim(const Duration(minutes: 1)));

    await writes.setQueueMessage(id, "Today's limit is used.");

    final ProcessingJob job = await stored(id);
    expect(job.status, JobStatus.queued);
    expect(job.lastError, "Today's limit is used.");
    expect(job.leaseExpiresAt, isNull);
  });

  test('rejections append without duplicates and read back', () async {
    final String id = _ok(await repository.enqueue('record-1'));
    expect(await writes.rejections(id), isEmpty);

    await writes.appendRejections(id, <String>['No evidence for year.']);
    await writes.appendRejections(id, <String>[
      'No evidence for year.',
      'Serial breaks its pattern.',
    ]);

    expect(await writes.rejections(id), <String>[
      'No evidence for year.',
      'Serial breaks its pattern.',
    ]);
  });

  test(
    'rejections for a missing job are empty and appending is a no-op',
    () async {
      await writes.appendRejections('missing', <String>['Anything.']);

      expect(await writes.rejections('missing'), isEmpty);
    },
  );
}

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) => throw failure, (T value) => value);
}
