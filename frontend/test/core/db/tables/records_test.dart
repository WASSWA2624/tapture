import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
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
  final DateTime t2 = t0.add(const Duration(seconds: 4));

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'paged listing by project and status, and lookup by identityHash',
    () async {
      _ok(
        await upsertRecord(
          db,
          row: _record(projectId: 'p1', identityHash: 'h-old', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertRecord(
          db,
          row: _record(projectId: 'p1', identityHash: 'h-mid', capturedAt: t1),
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final RecordRow newest = _ok(
        await upsertRecord(
          db,
          row: _record(projectId: 'p1', identityHash: 'h-new', capturedAt: t2),
          clock: FixedClock(t2),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertRecord(
          db,
          row: _record(
            projectId: 'p1',
            identityHash: 'h-draft',
            status: 'draft',
            capturedAt: t2,
          ),
          clock: FixedClock(t2),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertRecord(
          db,
          row: _record(
            projectId: 'p2',
            identityHash: 'h-other',
            capturedAt: t2,
          ),
          clock: FixedClock(t2),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final List<String> page = _ok(
        await listRecordsByProjectAndStatus(
          db,
          projectId: 'p1',
          status: 'captured',
          offset: 0,
          limit: 2,
        ),
      ).map((RecordRow row) => row.identityHash).toList();
      expect(page, <String>['h-new', 'h-mid']);

      final List<String> rest = _ok(
        await listRecordsByProjectAndStatus(
          db,
          projectId: 'p1',
          status: 'captured',
          offset: 2,
          limit: 2,
        ),
      ).map((RecordRow row) => row.identityHash).toList();
      expect(rest, <String>['h-old']);

      final RecordRow? found = _ok(
        await lookupRecordByIdentityHash(db, identityHash: 'h-new'),
      );
      expect(found?.id, newest.id);
    },
  );

  test(
    'the project-status list is served by records_by_project_status',
    () async {
      _ok(
        await upsertRecord(
          db,
          row: _record(projectId: 'p1', identityHash: 'h1', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertRecord(
          db,
          row: _record(
            projectId: 'p1',
            identityHash: 'h2',
            status: 'draft',
            capturedAt: t0,
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertRecord(
          db,
          row: _record(projectId: 'p2', identityHash: 'h3', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final List<QueryRow> plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM records '
            "WHERE project_id = 'p1' AND status = 'captured' "
            'ORDER BY captured_at DESC',
          )
          .get();
      final String details = plan
          .map((QueryRow row) => row.read<String>('detail'))
          .join('; ');
      expect(details, contains('records_by_project_status'));
    },
  );

  test('version 5 creates the records table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_records_',
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
      await _columns(upgraded, 'records'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'project_id',
        'template_id',
        'template_row_id',
        'status',
        'processing_mode',
        'context_json',
        'identity_hash',
        'source',
        'captured_at',
        'captured_by',
        'gps_lat',
        'gps_lon',
        'approved_at',
        'approved_by',
      ]),
    );
  });
}

RecordsCompanion _record({
  required String projectId,
  required String identityHash,
  required DateTime capturedAt,
  String status = 'captured',
}) {
  return RecordsCompanion(
    projectId: Value<String>(projectId),
    templateId: const Value<String>('t1'),
    status: Value<String>(status),
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
