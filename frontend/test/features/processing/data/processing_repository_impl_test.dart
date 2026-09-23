import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_processing_repository.dart';

void main() {
  late AppDatabase db;
  final DateTime t0 = DateTime.utc(2026, 9, 23, 8);

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  ProcessingRepositoryImpl repo(Clock clock) {
    return ProcessingRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
      settings: SettingsStore.fake(),
    );
  }

  test('save then byId round-trips stage, skip and rejections', () async {
    final ProcessingRepositoryImpl store = repo(FixedClock(t0));
    final ProcessingJob saved = _ok(
      await store.save(
        ProcessingJob(
          id: 'job-1',
          recordId: 'record-1',
          stage: 'prepare',
          skipReason: 'filled locally',
          rejections: const <String>['No evidence supports year.'],
          queuedAt: t0,
        ),
      ),
    );
    final ProcessingJob? loaded = _ok(await store.byId(saved.id));
    expect(loaded?.stage, 'prepare');
    expect(loaded?.recordId, 'record-1');
    expect(loaded?.skipReason, 'filled locally');
    expect(loaded?.rejections, <String>['No evidence supports year.']);
    expect(await store.watchAll().first, hasLength(1));
  });

  test('two claims never return the same job', () async {
    final ProcessingRepositoryImpl store = repo(FixedClock(t0));
    await store.enqueue('record-a');
    await store.enqueue('record-b');
    final List<Result<ProcessingJob?>> results =
        await Future.wait(<Future<Result<ProcessingJob?>>>[
          store.claim(const Duration(minutes: 1)),
          store.claim(const Duration(minutes: 1)),
        ]);
    final List<ProcessingJob?> claimed = <ProcessingJob?>[
      for (final Result<ProcessingJob?> result in results) _ok(result),
    ];
    final Set<String> ids = claimed
        .whereType<ProcessingJob>()
        .map((ProcessingJob job) => job.id)
        .toSet();
    expect(ids, hasLength(2));
  });

  test('an expired lease can be claimed again', () async {
    final ProcessingRepositoryImpl first = repo(FixedClock(t0));
    final String id = _ok(await first.enqueue('record-1'));
    final ProcessingJob? claimed = _ok(
      await first.claim(const Duration(minutes: 1)),
    );
    expect(claimed?.id, id);
    expect(claimed?.status, JobStatus.running);

    final ProcessingRepositoryImpl later = repo(
      FixedClock(t0.add(const Duration(minutes: 2))),
    );
    final ProcessingJob? again = _ok(
      await later.claim(const Duration(minutes: 1)),
    );
    expect(again?.id, id);
    expect(again?.status, JobStatus.running);
  });

  test('process all queues raw-saved records exactly once', () async {
    await db.close();
    db = await seededDatabase(records: 2);
    final ProcessingRepositoryImpl store = repo(FixedClock(t0));

    final QueueSnapshot before = await store.watchQueue().first;
    expect(before.unprocessed, 2);
    expect(before.queued, 0);
    expect(before.groups.single.records, 2);

    expect(_ok(await store.enqueuePending()), 2);
    expect(_ok(await store.enqueuePending()), 0);

    final QueueSnapshot after = await store.watchQueue().first;
    expect(after.unprocessed, 0);
    expect(after.queued, 2);
    expect(await store.watchAll().first, hasLength(2));
  });

  test('a failed job is not also counted as unprocessed', () async {
    await db.close();
    db = await seededDatabase(records: 1);
    final ProcessingRepositoryImpl store = repo(FixedClock(t0));
    _ok(await store.enqueuePending());
    final ProcessingJob job = _ok(
      await store.claim(const Duration(minutes: 1)),
    )!;

    _ok(await store.fail(job.id, 'Missing template.', permanent: true));

    final QueueSnapshot snapshot = await store.watchQueue().first;
    expect(snapshot.failed, 1);
    expect(snapshot.unprocessed, 0);
    expect(snapshot.groups, isEmpty);
  });

  test('the fake the later tests use round-trips a job', () async {
    final FakeProcessingRepository fake = FakeProcessingRepository();
    addTearDown(fake.dispose);
    _ok(
      await fake.save(
        const ProcessingJob(
          id: 'job-1',
          recordId: 'record-1',
          stage: 'prepare',
        ),
      ),
    );
    expect(_ok(await fake.byId('job-1'))?.stage, 'prepare');
  });
}

T _ok<T>(Result<T> result) {
  return result.fold((failure) => throw TestFailure(failure.message), (value) {
    return value;
  });
}
