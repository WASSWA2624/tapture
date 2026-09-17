import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;
  late String recordId;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  setUp(() async {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
    recordId = _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          projectId: const Value<String>('p1'),
          templateId: const Value<String>('t1'),
          status: const Value<String>('captured'),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>('{}'),
          identityHash: const Value<String>('h1'),
          source: const Value<String>('capture'),
          capturedAt: Value<DateTime>(t0),
          capturedBy: const Value<String>('Ada'),
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    ).id;
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'refinement leaves valueRaw byte-identical and a second raw write is refused',
    () async {
      const String raw = 'SN-001';
      final RecordField created = _ok(
        await insertRecordField(
          db,
          row: RecordFieldsCompanion(
            recordId: Value<String>(recordId),
            fieldKey: const Value<String>('serial'),
            valueRaw: const Value<String>(raw),
            source: const Value<String>('typed'),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(created.valueRaw, raw);

      final RecordField refined = _ok(
        await writeRecordFieldRefined(
          db,
          id: created.id,
          valueRefined: 'SN-001-clean',
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(refined.valueRaw, raw);
      expect(refined.valueRefined, 'SN-001-clean');

      final Result<RecordField> secondRaw = await insertRecordField(
        db,
        row: RecordFieldsCompanion(
          id: Value<String>(created.id),
          valueRaw: const Value<String>('changed'),
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      );
      expect(
        secondRaw.fold((Failure failure) => failure, (_) => null),
        isA<StorageFailure>(),
      );
      final RecordField stored =
          await (db.select(db.recordFields)
                ..where(($RecordFieldsTable tbl) => tbl.id.equals(created.id)))
              .getSingle();
      expect(stored.valueRaw, raw);
    },
  );

  test(
    'a duplicate fieldKey for one record is refused by the unique index',
    () async {
      _ok(
        await insertRecordField(
          db,
          row: RecordFieldsCompanion(
            recordId: Value<String>(recordId),
            fieldKey: const Value<String>('serial'),
            valueRaw: const Value<String>('a'),
            source: const Value<String>('typed'),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final Result<RecordField> duplicate = await insertRecordField(
        db,
        row: RecordFieldsCompanion(
          recordId: Value<String>(recordId),
          fieldKey: const Value<String>('serial'),
          valueRaw: const Value<String>('b'),
          source: const Value<String>('typed'),
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      );
      late StorageFailure failure;
      duplicate.fold((Failure value) {
        failure = value as StorageFailure;
      }, (_) => fail('expected a uniqueness failure'));
      expect(failure.message, contains('already exists'));
      expect(failure.recoveryAction, isNotEmpty);
    },
  );

  test(
    'version 5 creates the record_fields table with merge columns',
    () async {
      await db.close();
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_record_fields_',
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
        await _columns(upgraded, 'record_fields'),
        containsAll(<String>[
          'id',
          'created_at',
          'updated_at',
          'updated_by_device',
          'rev',
          'record_id',
          'field_key',
          'value_raw',
          'value_refined',
          'value_final',
          'confidence',
          'source',
          'verified',
          'verified_by',
          'verified_at',
        ]),
      );
    },
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
