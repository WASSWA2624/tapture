import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/device_profile.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final DateTime t1 = t0.add(const Duration(seconds: 2));

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'first launch inserts one row and a second launch does not duplicate it',
    () async {
      final DeviceProfileRow first = await ensureDeviceProfile(
        db,
        deviceId: 'device-a',
        clock: FixedClock(t0),
        operatorName: 'Ada',
      );
      final DeviceProfileRow second = await ensureDeviceProfile(
        db,
        deviceId: 'device-a',
        clock: FixedClock(t1),
        operatorName: 'Bea',
      );

      final List<DeviceProfileRow> rows = await db
          .select(db.deviceProfile)
          .get();
      expect(rows, hasLength(1));
      expect(first.id, second.id);
      expect(second.deviceId, 'device-a');
      expect(second.operatorName, 'Ada');
      expect(first.accountId, isNull);
      expect(second.accountId, isNull);
    },
  );

  test(
    'an in-memory database has a nullable accountId that reads as null',
    () async {
      final DeviceProfileRow row = await ensureDeviceProfile(
        db,
        deviceId: 'device-a',
        clock: FixedClock(t0),
        operatorName: 'Ada',
      );
      final Set<String> columns = await _columns(db, 'device_profile');
      expect(columns, contains('account_id'));
      expect(row.accountId, isNull);
    },
  );

  test(
    'upgrading an in-memory version 12 profile adds a null accountId',
    () async {
      await db.close();
      final AppDatabase upgraded = AppDatabase(
        NativeDatabase.memory(
          setup: (Database database) {
            database.execute('PRAGMA journal_mode = WAL;');
            database.execute('PRAGMA foreign_keys = ON;');
            database.execute('''
CREATE TABLE device_profile (
  id TEXT NOT NULL PRIMARY KEY,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  updated_by_device TEXT NOT NULL,
  rev INTEGER NOT NULL DEFAULT 1,
  device_id TEXT NOT NULL,
  operator_name TEXT NOT NULL DEFAULT '',
  preferences TEXT NOT NULL DEFAULT '{}'
)
''');
            database.execute('''
INSERT INTO device_profile (
  id, created_at, updated_at, updated_by_device, rev,
  device_id, operator_name, preferences
) VALUES ('local', 0, 0, 'device-a', 1, 'device-a', 'Ada', '{}')
''');
            database.execute('PRAGMA user_version = 12');
          },
        ),
      );
      addTearDown(upgraded.close);
      await upgraded.customSelect('SELECT 1').get();

      final Set<String> columns = await _columns(upgraded, 'device_profile');
      expect(columns, contains('account_id'));
      final DeviceProfileIdentity identity = await readDeviceProfile(
        upgraded,
        deviceId: 'device-a',
        clock: FixedClock(t0),
      );
      expect(identity.operatorName, 'Ada');
      expect(identity.accountId, isNull);
    },
  );

  test(
    'writing the profile updates the one row and never inserts a second',
    () async {
      await ensureDeviceProfile(
        db,
        deviceId: 'device-a',
        clock: FixedClock(t0),
        operatorName: 'Ada',
      );
      final DeviceProfileIdentity first = await writeDeviceProfile(
        db,
        deviceId: 'device-a',
        operatorName: 'Bea',
        preferences: '{"operatorInitials":"B"}',
        clock: FixedClock(t1),
      );
      final DeviceProfileIdentity second = await writeDeviceProfile(
        db,
        deviceId: 'device-a',
        operatorName: 'Bea',
        preferences: '{"operatorInitials":"B","operatorContact":"bea@x"}',
        clock: FixedClock(t1),
      );

      final List<DeviceProfileRow> rows = await db
          .select(db.deviceProfile)
          .get();
      expect(rows, hasLength(1));
      expect(first.operatorName, 'Bea');
      expect(second.accountId, isNull);
      expect(rows.single.operatorName, 'Bea');
    },
  );

  test(
    'a record captured after a profile write carries that operator name',
    () async {
      await writeDeviceProfile(
        db,
        deviceId: 'device-a',
        operatorName: 'Ada Lovelace',
        preferences: '{}',
        clock: FixedClock(t0),
      );
      final DeviceProfileIdentity identity = await readDeviceProfile(
        db,
        deviceId: 'device-a',
        clock: FixedClock(t0),
      );
      final RecordRow record = _ok(
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
            capturedBy: Value<String>(identity.operatorName),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: UuidV7Service.sequence(FixedClock(t0)),
        ),
      );
      expect(record.capturedBy, 'Ada Lovelace');
    },
  );

  test(
    'version 2 creates the device_profile table with merge columns',
    () async {
      await db.close();
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_profile_',
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

      final Set<String> columns = await _columns(upgraded, 'device_profile');
      expect(
        columns,
        containsAll(<String>[
          'id',
          'created_at',
          'updated_at',
          'updated_by_device',
          'rev',
          'device_id',
          'operator_name',
          'preferences',
          'account_id',
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
