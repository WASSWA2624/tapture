import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/variances.dart';
import 'package:tapture/core/db/transactions.dart';
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
    'register versus found round-trips and the unique index holds one row',
    () async {
      final RecordRow record = _ok(
        await upsertRecord(
          db,
          row: _record(capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final Variance first = _ok(
        await upsertVariance(
          db,
          row: VariancesCompanion(
            projectId: const Value<String>('p1'),
            recordId: Value<String>(record.id),
            fieldKey: const Value<String>('serial'),
            registerValue: const Value<String>('SN-001'),
            foundValue: const Value<String>('SN-002'),
            status: const Value<String>('changed'),
            resolvedBy: const Value<String>('detector'),
            resolvedAt: Value<DateTime>(t0),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(first.registerValue, 'SN-001');
      expect(first.foundValue, 'SN-002');
      expect(first.status, 'changed');
      expect(first.resolvedBy, isNull);
      expect(first.resolvedAt, isNull);

      final Variance second = _ok(
        await upsertVariance(
          db,
          row: VariancesCompanion(
            projectId: const Value<String>('p1'),
            recordId: Value<String>(record.id),
            fieldKey: const Value<String>('serial'),
            registerValue: const Value<String>('SN-001'),
            foundValue: const Value<String>('SN-009'),
            status: const Value<String>('changed'),
          ),
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(second.id, first.id);
      expect(second.foundValue, 'SN-009');
      expect(await db.select(db.variances).get(), hasLength(1));

      try {
        await db
            .into(db.variances)
            .insert(
              VariancesCompanion(
                createdAt: Value<DateTime>(t1),
                updatedAt: Value<DateTime>(t1),
                updatedByDevice: const Value<String>('device-a'),
                projectId: const Value<String>('p1'),
                recordId: Value<String>(record.id),
                fieldKey: const Value<String>('serial'),
                registerValue: const Value<String>('SN-001'),
                foundValue: const Value<String>('SN-010'),
                status: const Value<String>('changed'),
              ),
            );
        fail('expected a uniqueness failure');
      } on Object catch (error) {
        expect(storageFailureFrom(error).message, contains('already exists'));
      }
    },
  );

  test(
    'an unresolved queue is listed by project and status through the index',
    () async {
      final RecordRow record = _ok(
        await upsertRecord(
          db,
          row: _record(capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final Variance serial = _ok(
        await upsertVariance(
          db,
          row: _variance(
            recordId: record.id,
            fieldKey: 'serial',
            foundValue: 'SN-002',
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertVariance(
          db,
          row: _variance(
            recordId: record.id,
            fieldKey: 'make',
            foundValue: 'Acme',
            status: 'match',
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertVariance(
          db,
          row: _variance(
            projectId: 'p2',
            recordId: record.id,
            fieldKey: 'model',
            foundValue: 'X1',
          ),
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final List<String> page = _ok(
        await listVariancesByProjectAndStatus(
          db,
          projectId: 'p1',
          status: 'changed',
          offset: 0,
          limit: 10,
        ),
      ).map((Variance row) => row.id).toList();
      expect(page, <String>[serial.id]);

      final List<QueryRow> plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM variances '
            "WHERE project_id = 'p1' AND status = 'changed'",
          )
          .get();
      expect(
        plan.map((QueryRow row) => row.read<String>('detail')).join('; '),
        contains('variances_by_project_status'),
      );
    },
  );

  test(
    'resolving records the operator and timestamp and leaves the source record',
    () async {
      final RecordRow record = _ok(
        await upsertRecord(
          db,
          row: _record(capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final Variance row = _ok(
        await upsertVariance(
          db,
          row: _variance(
            recordId: record.id,
            fieldKey: 'serial',
            foundValue: 'SN-002',
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final Variance resolved = _ok(
        await resolveVariance(
          db,
          id: row.id,
          resolvedBy: 'Ada',
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(resolved.status, 'changed');
      expect(resolved.registerValue, 'SN-001');
      expect(resolved.foundValue, 'SN-002');
      expect(resolved.resolvedBy, 'Ada');
      expect(resolved.resolvedAt!.isAtSameMomentAs(t1), isTrue);
      expect(
        await (db.select(
          db.records,
        )..where(($RecordsTable tbl) => tbl.id.equals(record.id))).getSingle(),
        isNotNull,
      );
    },
  );

  test('version 9 creates the variances table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_variances_',
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
      await _columns(upgraded, 'variances'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'project_id',
        'record_id',
        'field_key',
        'register_value',
        'found_value',
        'status',
        'resolved_by',
        'resolved_at',
      ]),
    );
  });
}

VariancesCompanion _variance({
  String projectId = 'p1',
  required String recordId,
  required String fieldKey,
  required String foundValue,
  String status = 'changed',
}) {
  return VariancesCompanion(
    projectId: Value<String>(projectId),
    recordId: Value<String>(recordId),
    fieldKey: Value<String>(fieldKey),
    registerValue: const Value<String>('SN-001'),
    foundValue: Value<String>(foundValue),
    status: Value<String>(status),
  );
}

RecordsCompanion _record({required DateTime capturedAt}) {
  return RecordsCompanion(
    projectId: const Value<String>('p1'),
    templateId: const Value<String>('t1'),
    status: const Value<String>('captured'),
    processingMode: const Value<String>('manual'),
    contextJson: const Value<String>('{}'),
    identityHash: const Value<String>('h1'),
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
