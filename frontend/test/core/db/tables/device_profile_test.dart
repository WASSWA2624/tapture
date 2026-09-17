import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/device_profile.dart';
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
