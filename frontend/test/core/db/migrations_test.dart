import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/migrations.dart';
import 'package:tapture/core/errors/failure.dart';

void main() {
  tearDown(clearExportAcknowledgement);

  test('every schema version has a named upgrade step and a test', () {
    final String tests = File(
      'test/core/db/migrations_test.dart',
    ).readAsStringSync();
    expect(kUpgradeSteps.length, kSchemaVersion);
    for (int version = 1; version <= kSchemaVersion; version++) {
      expect(
        kUpgradeSteps.containsKey(version),
        isTrue,
        reason: 'schema version $version has no named upgrade step',
      );
      expect(
        tests,
        contains('version $version'),
        reason: 'schema version $version has no migration test',
      );
    }
  });

  test(
    'upgrade from a seeded version 1 file through version 2 and version 3 to head preserves rows and columns',
    () async {
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_migrate_',
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
      await upgraded.customSelect('SELECT 1').get();
      final Map<String, Set<String>> upgradedColumns = await _columnSets(
        upgraded,
      );
      final Map<String, int> upgradedRows = await _rowCounts(upgraded);
      await upgraded.close();

      final AppDatabase fresh = AppDatabase.memory();
      addTearDown(fresh.close);
      await fresh.customSelect('SELECT 1').get();

      expect(upgradedColumns, await _columnSets(fresh));
      expect(upgradedRows, await _rowCounts(fresh));
    },
  );

  test(
    'a destructive step refuses to run without the export acknowledgement',
    () {
      expect(
        () => ensureExportAcknowledged(isDestructive: true),
        throwsA(isA<StorageFailure>()),
      );
      acknowledgeExport();
      expect(
        () => ensureExportAcknowledged(isDestructive: true),
        returnsNormally,
      );
      expect(
        () => ensureExportAcknowledged(isDestructive: false),
        returnsNormally,
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

Future<Map<String, Set<String>>> _columnSets(AppDatabase db) async {
  final List<QueryRow> tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      )
      .get();
  final Map<String, Set<String>> columns = <String, Set<String>>{};
  for (final QueryRow table in tables) {
    final String name = table.read<String>('name');
    final List<QueryRow> info = await db
        .customSelect('PRAGMA table_info("$name")')
        .get();
    columns[name] = <String>{
      for (final QueryRow row in info) row.read<String>('name'),
    };
  }
  return columns;
}

Future<Map<String, int>> _rowCounts(AppDatabase db) async {
  final Map<String, Set<String>> columns = await _columnSets(db);
  final Map<String, int> counts = <String, int>{};
  for (final String table in columns.keys) {
    final QueryRow row = await db
        .customSelect('SELECT COUNT(*) AS c FROM "$table"')
        .getSingle();
    counts[table] = row.read<int>('c');
  }
  return counts;
}
