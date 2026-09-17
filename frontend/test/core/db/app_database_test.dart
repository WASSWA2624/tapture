import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';

void main() {
  test('an in-memory database opens and closes cleanly', () async {
    final AppDatabase db = AppDatabase.memory();

    await db.customSelect('SELECT 1').get();
    expect(db.schemaVersion, kSchemaVersion);

    await db.close();

    expect(() => db.customSelect('SELECT 1').get(), throwsA(isA<Object>()));
  });

  test(
    'a file database reopens after a close with no lock left behind',
    () async {
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_db_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final AppDatabase first = AppDatabase.open(directoryPath: directory.path);
      await first.customSelect('SELECT 1').get();
      expect(await _pragma(first, 'foreign_keys'), 1);
      expect((await _pragmaString(first, 'journal_mode')).toLowerCase(), 'wal');
      await first.close();

      final AppDatabase second = AppDatabase.open(
        directoryPath: directory.path,
      );
      await second.customSelect('SELECT 1').get();
      expect(second.schemaVersion, kSchemaVersion);
      expect(await _pragma(second, 'foreign_keys'), 1);
      expect(
        (await _pragmaString(second, 'journal_mode')).toLowerCase(),
        'wal',
      );
      await second.close();
    },
  );
}

Future<int> _pragma(AppDatabase db, String name) async {
  final QueryRow row = await db.customSelect('PRAGMA $name').getSingle();
  final Object? value = row.data.values.first;
  if (value is int) {
    return value;
  }
  return int.parse('$value');
}

Future<String> _pragmaString(AppDatabase db, String name) async {
  final QueryRow row = await db.customSelect('PRAGMA $name').getSingle();
  return '${row.data.values.first}';
}
