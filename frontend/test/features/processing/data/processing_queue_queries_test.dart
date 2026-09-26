import 'package:drift/drift.dart'
    show OrderClauseGenerator, OrderingTerm, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/processing.dart' as jobs;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/data/processing_queue_queries.dart';
import 'package:tapture/features/processing/data/processing_queue_writes.dart';
import 'package:tapture/features/processing/data/response_store.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';

void main() {
  late AppDatabase db;
  late List<RecordRow> records;
  final DateTime now = DateTime.utc(2026, 9, 26, 8);
  final FixedClock clock = FixedClock(now);
  final SettingsStore settings = SettingsStore.fake(
    stored: <String, Object?>{SettingKeys.aiDailyRequestCap.name: 40},
  );

  setUp(() async {
    db = await seededDatabase(records: 4);
    records =
        await (db.select(db.records)
              ..orderBy(<OrderClauseGenerator<$RecordsTable>>[
                ($RecordsTable t) => OrderingTerm.asc(t.id),
              ]))
            .get();
  });

  tearDown(() => db.close());

  ProcessingQueueQueries queries() {
    return ProcessingQueueQueries(db: db, clock: clock, settings: settings);
  }

  ProcessingQueueWrites writes() {
    return ProcessingQueueWrites(
      db: db,
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
      settings: settings,
      queries: queries(),
    );
  }

  Future<void> placeIn(RecordRow record, String contextJson) async {
    await (db.update(db.records)
          ..where(($RecordsTable t) => t.id.equals(record.id)))
        .write(RecordsCompanion(contextJson: Value<String>(contextJson)));
  }

  /// One id sequence for every stored response, so no save replaces another.
  final UuidV7Service responseIds = UuidV7Service.sequence(
    FixedClock(DateTime.utc(2026, 1, 1)),
  );

  Future<void> respond(String jobId, String summary, {DateTime? at}) async {
    _ok(
      await ResponseStore(
        db: db,
        clock: FixedClock(at ?? now),
        deviceId: 'device-a',
        ids: responseIds,
      ).save(
        jobId: jobId,
        requestSummary: summary,
        rawResponse: '{}',
        parsedOk: true,
      ),
    );
  }

  test('the snapshot counts from queries, by status', () async {
    await placeIn(records[0], '{"district":"Kampala","room":"Plant room"}');
    await placeIn(records[1], '{"district":"Kampala","room":"Plant room"}');
    final ProcessingQueueWrites queue = writes();
    final String queued = _ok(await queue.enqueue(records[0].id));
    final String failed = _ok(await queue.enqueue(records[2].id));
    _ok(await queue.fail(failed, 'Unreadable.', permanent: true));

    final QueueSnapshot snapshot = await queries().snapshot();

    expect(snapshot.unprocessed, 2, reason: 'records 1 and 3 have no job');
    expect(snapshot.queued, 1);
    expect(snapshot.failed, 1);
    expect(snapshot.failures.single.id, failed);
    expect(snapshot.failures.single.lastError, 'Unreadable.');
    expect(
      <String, int>{
        for (final QueueGroup group in snapshot.groups)
          group.label: group.records,
      },
      <String, int>{'Kampala / Plant room': 2, 'Unassigned': 1},
    );
    expect(queued, isNotEmpty);
    expect(
      await queries().count(jobs.ProcessingJobStatus.queued),
      snapshot.queued,
    );
  });

  test('a project filter keeps other projects out', () async {
    final QueueSnapshot other = await queries().snapshot(
      projectId: 'another-project',
    );

    expect(other.unprocessed, 0);
    expect(other.groups, isEmpty);
    expect(
      (await queries().snapshot(projectId: records[0].projectId)).unprocessed,
      4,
    );
  });

  test("today's usage counts online requests and their images", () async {
    final String id = _ok(await writes().enqueue(records[0].id));
    await respond(id, '{"kind":"online","images":["a","b"]}');
    await respond(id, '{"kind":"online","imageCount":3}');
    await respond(id, '{"kind":"transcript","attachmentId":"a1"}');
    await respond(
      id,
      '{"kind":"online","imageCount":9}',
      at: now.subtract(const Duration(days: 1)),
    );

    final ({int requests, int images}) usage = await queries().usageOn(now);

    expect(usage, (requests: 2, images: 5));
    final QueueSnapshot snapshot = await queries().snapshot();
    expect(snapshot.requestsToday, 2);
    expect(snapshot.imagesToday, 5);
    expect(snapshot.requestCap, 40);
  });

  test('a project with its own cap shows that cap', () async {
    await (db.update(
      db.projects,
    )..where(($ProjectsTable t) => t.id.equals(records[0].projectId))).write(
      const ProjectsCompanion(
        settings: Value<String>('{"dailyRequestCap":12}'),
      ),
    );

    expect(
      (await queries().snapshot(projectId: records[0].projectId)).requestCap,
      12,
    );
    expect((await queries().snapshot()).requestCap, 40);
  });

  test('a context label joins the known levels in order', () {
    expect(
      ProcessingQueueQueries.contextLabel(
        '{"room":"Plant room","district":"Kampala","facility":"Mulago"}',
      ),
      'Kampala / Mulago / Plant room',
    );
    expect(ProcessingQueueQueries.contextLabel('{}'), 'Unassigned');
    expect(ProcessingQueueQueries.contextLabel('[]'), 'Unassigned');
    expect(ProcessingQueueQueries.contextLabel('not json'), 'Unassigned');
  });
}

T _ok<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw TestFailure(failure.message),
    (T value) => value,
  );
}
