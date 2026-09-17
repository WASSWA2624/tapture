import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/duplicates.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final DateTime t1 = t0.add(const Duration(seconds: 2));

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'the same pair is unique regardless of argument order and updates in place',
    () async {
      final RecordRow left = _ok(
        await upsertRecord(
          db,
          row: _record(identityHash: 'h-left', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final RecordRow right = _ok(
        await upsertRecord(
          db,
          row: _record(identityHash: 'h-right', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final DuplicatePair first = _ok(
        await upsertDetectedDuplicate(
          db,
          row: DuplicatesCompanion(
            projectId: const Value<String>('p1'),
            leftRecordId: Value<String>(right.id),
            rightRecordId: Value<String>(left.id),
            signal: const Value<String>('identity'),
            score: const Value<double>(0.4),
            resolution: const Value<String>('keepBoth'),
            resolvedBy: const Value<String>('detector'),
            resolvedAt: Value<DateTime>(t0),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(first.leftRecordId.compareTo(first.rightRecordId), lessThan(0));
      expect(first.score, 0.4);
      expect(first.status, DuplicatePairStatus.unresolved);
      expect(first.resolution, isNull);
      expect(first.resolvedBy, isNull);
      expect(first.resolvedAt, isNull);

      final DuplicatePair second = _ok(
        await upsertDetectedDuplicate(
          db,
          row: DuplicatesCompanion(
            projectId: const Value<String>('p1'),
            leftRecordId: Value<String>(left.id),
            rightRecordId: Value<String>(right.id),
            signal: const Value<String>('samePhoto'),
            score: const Value<double>(0.9),
          ),
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(second.id, first.id);
      expect(second.signal, 'samePhoto');
      expect(second.score, 0.9);
      expect(second.status, DuplicatePairStatus.unresolved);
      expect(second.resolution, isNull);
      expect(await db.select(db.duplicates).get(), hasLength(1));
    },
  );

  test(
    'an unresolved queue is listed by project and status through the index',
    () async {
      final RecordRow a = _ok(
        await upsertRecord(
          db,
          row: _record(identityHash: 'h-a', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final RecordRow b = _ok(
        await upsertRecord(
          db,
          row: _record(identityHash: 'h-b', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final RecordRow c = _ok(
        await upsertRecord(
          db,
          row: _record(identityHash: 'h-c', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final DuplicatePair older = _ok(
        await upsertDetectedDuplicate(
          db,
          row: _pair(left: a.id, right: b.id, score: 0.5),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertDetectedDuplicate(
          db,
          row: _pair(left: a.id, right: c.id, score: 0.6),
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertDetectedDuplicate(
          db,
          row: _pair(projectId: 'p2', left: b.id, right: c.id, score: 0.7),
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final List<String> page = _ok(
        await listDuplicatesByProjectAndStatus(
          db,
          projectId: 'p1',
          status: DuplicatePairStatus.unresolved,
          offset: 0,
          limit: 1,
        ),
      ).map((DuplicatePair row) => row.id).toList();
      expect(page, <String>[older.id]);

      final List<QueryRow> plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM duplicates '
            "WHERE project_id = 'p1' AND status = 'unresolved'",
          )
          .get();
      expect(
        plan.map((QueryRow row) => row.read<String>('detail')).join('; '),
        contains('duplicates_by_project_status'),
      );
    },
  );

  test(
    'resolving records the operator and timestamp and leaves both records',
    () async {
      final RecordRow left = _ok(
        await upsertRecord(
          db,
          row: _record(identityHash: 'h-left', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final RecordRow right = _ok(
        await upsertRecord(
          db,
          row: _record(identityHash: 'h-right', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final DuplicatePair pair = _ok(
        await upsertDetectedDuplicate(
          db,
          row: _pair(left: left.id, right: right.id, score: 0.8),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final DuplicatePair resolved = _ok(
        await resolveDuplicate(
          db,
          id: pair.id,
          resolution: 'keepBoth',
          resolvedBy: 'Ada',
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(resolved.status, DuplicatePairStatus.resolved);
      expect(resolved.resolution, 'keepBoth');
      expect(resolved.resolvedBy, 'Ada');
      expect(resolved.resolvedAt!.isAtSameMomentAs(t1), isTrue);
      expect(
        await (db.select(
          db.records,
        )..where(($RecordsTable tbl) => tbl.id.equals(left.id))).getSingle(),
        isNotNull,
      );
      expect(
        await (db.select(
          db.records,
        )..where(($RecordsTable tbl) => tbl.id.equals(right.id))).getSingle(),
        isNotNull,
      );
      expect(
        _ok(
          await listDuplicatesByProjectAndStatus(
            db,
            projectId: 'p1',
            status: DuplicatePairStatus.unresolved,
            offset: 0,
            limit: 10,
          ),
        ),
        isEmpty,
      );
    },
  );

  test('version 9 creates the duplicates table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_duplicates_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final File seed = File('${directory.path}/tapture.sqlite');
    _seedVersion1(seed);

    final AppDatabase upgraded = AppDatabase.open(
      directoryPath: directory.path,
    );
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();

    expect(
      await _columns(upgraded, 'duplicates'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'project_id',
        'left_record_id',
        'right_record_id',
        'signal',
        'score',
        'status',
        'resolution',
        'resolved_by',
        'resolved_at',
      ]),
    );
  });
}

DuplicatesCompanion _pair({
  String projectId = 'p1',
  required String left,
  required String right,
  required double score,
}) {
  return DuplicatesCompanion(
    projectId: Value<String>(projectId),
    leftRecordId: Value<String>(left),
    rightRecordId: Value<String>(right),
    signal: const Value<String>('identity'),
    score: Value<double>(score),
  );
}

RecordsCompanion _record({
  required String identityHash,
  required DateTime capturedAt,
}) {
  return RecordsCompanion(
    projectId: const Value<String>('p1'),
    templateId: const Value<String>('t1'),
    status: const Value<String>('captured'),
    processingMode: const Value<String>('manual'),
    contextJson: const Value<String>('{}'),
    identityHash: Value<String>(identityHash),
    source: const Value<String>('capture'),
    capturedAt: Value<DateTime>(capturedAt),
    capturedBy: const Value<String>('Ada'),
  );
}

void _seedVersion1(File file) {
  file.parent.createSync(recursive: true);
  final Database database = sqlite3.open(file.path);
  database.execute('PRAGMA user_version = 1');
  database.dispose();
}

Future<Set<String>> _columns(AppDatabase db, String table) async {
  final List<QueryRow> info = await db
      .customSelect('PRAGMA table_info("$table")')
      .get();
  return <String>{for (final QueryRow row in info) row.read<String>('name')};
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
