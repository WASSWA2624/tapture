@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart';
import 'package:tapture/core/db/app_database.dart';

import 'screen_database.dart';

void main() {
  test(
    'real WASM connections isolate rows, enforce keys and reopen after close',
    () async {
      final List<AppDatabase> open = <AppDatabase>[];
      AppDatabase create() {
        final AppDatabase database = createScreenDatabase();
        open.add(database);
        return database;
      }

      addTearDown(() async {
        for (final AppDatabase database in open) {
          await database.close();
        }
      });
      final AppDatabase first = create();
      final AppDatabase second = create();
      await _createProbe(first);
      await _createProbe(second);
      await first.customStatement('INSERT INTO screen_probe_parent VALUES (1)');
      await second.customStatement(
        'INSERT INTO screen_probe_parent VALUES (2)',
      );
      expect(await _rows(first), <int>[1]);
      expect(await _rows(second), <int>[2]);
      await first.customStatement('INSERT INTO screen_probe_child VALUES (1)');
      await expectLater(
        first.customStatement('INSERT INTO screen_probe_child VALUES (99)'),
        throwsA(
          isA<SqliteException>().having(
            (SqliteException error) => error.extendedResultCode,
            'foreign-key constraint',
            787,
          ),
        ),
      );
      await first.close();
      open.remove(first);

      final AppDatabase reopened = create();
      await _createProbe(reopened);
      expect(await _rows(reopened), isEmpty);
      expect(await _rows(second), <int>[2]);
      await expectLater(
        reopened.customStatement('INSERT INTO screen_probe_child VALUES (2)'),
        throwsA(isA<SqliteException>()),
      );
    },
  );
}

Future<void> _createProbe(AppDatabase database) async {
  final foreignKeys = await database
      .customSelect('PRAGMA foreign_keys')
      .getSingle();
  expect(foreignKeys.read<int>('foreign_keys'), 1);
  await database.customStatement(
    'CREATE TABLE screen_probe_parent (id INTEGER PRIMARY KEY)',
  );
  await database.customStatement(
    'CREATE TABLE screen_probe_child '
    '(parent_id INTEGER REFERENCES screen_probe_parent(id))',
  );
}

Future<List<int>> _rows(AppDatabase database) async {
  final rows = await database
      .customSelect('SELECT id FROM screen_probe_parent')
      .get();
  return rows.map((row) => row.read<int>('id')).toList();
}
