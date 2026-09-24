import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
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
    'upgrade from a seeded version 1 file through version 2 and version 3 and version 4 and version 5 and version 6 and version 7 and version 8 and version 9 and version 10 and version 11 and version 12 and version 13 and version 14 and version 15 and version 16 and version 17 and version 18 to head preserves rows and columns',
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

  test(
    'a native version 13 file upgrades through version 14 with projects intact',
    () async {
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_migrate_v13_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });
      final File seed = File('${directory.path}/tapture.sqlite');
      seed.parent.createSync(recursive: true);
      final Database raw = sqlite3.open(seed.path);
      _installVersion13Projects(raw);
      raw.dispose();

      final AppDatabase upgraded = AppDatabase.open(
        directoryPath: directory.path,
      );
      addTearDown(upgraded.close);
      await upgraded.customSelect('SELECT 1').get();
      await _expectVersion14Projects(upgraded);
    },
  );

  test(
    'an in-memory version 13 database upgrades through version 14 with projects intact',
    () async {
      final AppDatabase upgraded = AppDatabase(
        NativeDatabase.memory(
          setup: (Database database) {
            database.execute('PRAGMA journal_mode = WAL;');
            database.execute('PRAGMA foreign_keys = ON;');
            _installVersion13Projects(database);
          },
        ),
      );
      addTearDown(upgraded.close);
      await upgraded.customSelect('SELECT 1').get();
      await _expectVersion14Projects(upgraded);
    },
  );

  test(
    'an interrupted version 14 upgrade leaves version 13 rows usable',
    () async {
      final AppDatabase upgraded = AppDatabase(
        NativeDatabase.memory(
          setup: (Database database) {
            database.execute('PRAGMA journal_mode = WAL;');
            database.execute('PRAGMA foreign_keys = ON;');
            _installVersion13Projects(database);
            database.execute(
              'ALTER TABLE projects ADD COLUMN pinned_at INTEGER NULL',
            );
            database.execute('PRAGMA user_version = 13');
          },
        ),
      );
      addTearDown(upgraded.close);
      await upgraded.customSelect('SELECT 1').get();
      await _expectVersion14Projects(upgraded);
    },
  );

  test(
    'version 17 creates project-scoped capture sessions without changing projects',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await _insertProject(db);
      await db.customStatement('DROP TABLE capture_sessions');

      await migrateToV17(Migrator(db), db);
      await db.customStatement(
        'INSERT INTO capture_sessions '
        '(id, created_at, updated_at, updated_by_device, rev, '
        'project_id, payload_json) '
        "VALUES ('session-1', 1, 1, 'device-1', 1, 'project-1', "
        "'{\"id\":\"session-1\",\"projectId\":\"project-1\"}')",
      );

      expect(await _count(db, 'projects'), 1);
      expect(await _count(db, 'capture_sessions'), 1);
      final QueryRow row = await db
          .customSelect(
            "SELECT project_id, payload_json FROM capture_sessions "
            "WHERE id = 'session-1'",
          )
          .getSingle();
      expect(row.read<String>('project_id'), 'project-1');
      expect(row.read<String>('payload_json'), contains('session-1'));
    },
  );

  test(
    'version 18 creates attachment owners and preserves version 17 capture and attachment rows',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await _insertProject(db);
      await db.customStatement(
        'INSERT INTO capture_sessions '
        '(id, created_at, updated_at, updated_by_device, rev, '
        'project_id, payload_json) '
        "VALUES ('session-1', 1, 1, 'device-1', 1, 'project-1', '{}')",
      );
      await db.customStatement(
        'INSERT INTO attachments '
        '(id, created_at, updated_at, updated_by_device, rev, project_id, '
        'relative_path, mime_type, file_size, sha256, kind) '
        "VALUES ('audio-1', 1, 1, 'device-1', 1, 'project-1', "
        "'audio/one.wav', 'audio/wav', 4, 'hash-1', 'audio')",
      );
      await db.customStatement('DROP TABLE attachment_owners');

      await migrateToV18(Migrator(db), db);
      await db.customStatement(
        'INSERT INTO attachment_owners '
        '(id, created_at, updated_at, updated_by_device, rev, attachment_id, '
        'owner_type, owner_id, sort_order) '
        "VALUES ('owner-1', 1, 1, 'device-1', 1, 'audio-1', "
        "'record', 'record-1', 0)",
      );

      expect(await _count(db, 'capture_sessions'), 1);
      expect(await _count(db, 'attachments'), 1);
      expect(await _count(db, 'attachment_owners'), 1);
      final List<QueryRow> indexes = await db
          .customSelect("PRAGMA index_list('attachment_owners')")
          .get();
      expect(
        indexes.map((QueryRow row) => row.read<String>('name')),
        contains('attachment_owners_by_owner'),
      );
    },
  );

  test(
    'migrateToV16 is not a destructive step and a second run is a no-op',
    () async {
      expect(kDestructiveSteps.contains(16), isFalse);
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await migrateToV16(Migrator(db), db);
      await migrateToV16(Migrator(db), db);
      final Set<String> columns = (await _columnSets(db))['record_fields']!;
      expect(
        columns,
        containsAll(<String>[
          'confidence_band',
          'method',
          'provider',
          'model',
          'prompt_version',
        ]),
      );
      final Set<String> recordColumns = (await _columnSets(db))['records']!;
      expect(
        recordColumns,
        containsAll(<String>['row_match_strategy', 'row_match_score']),
      );
    },
  );

  test(
    'migrateToV15 is not a destructive step and a second run is a no-op',
    () async {
      expect(kDestructiveSteps.contains(15), isFalse);
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await migrateToV15(Migrator(db), db);
      await migrateToV15(Migrator(db), db);
      final Set<String> columns = (await _columnSets(db))['processing_jobs']!;
      expect(columns, contains('lease_expires_at'));
      expect((await _columnSets(db)).containsKey('ocr_cache'), isTrue);
    },
  );

  test(
    'migrateToV14 is not a destructive step and a second run is a no-op',
    () async {
      expect(kDestructiveSteps.contains(14), isFalse);
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await migrateToV14(Migrator(db), db);
      await migrateToV14(Migrator(db), db);
      await _expectVersion14Schema(db);
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

Future<void> _insertProject(AppDatabase db) {
  return db.customStatement(
    'INSERT INTO projects '
    '(id, created_at, updated_at, updated_by_device, rev, name, client, '
    'status, folder_name, settings) '
    "VALUES ('project-1', 1, 1, 'device-1', 1, 'Alpha', 'Acme', "
    "'active', 'alpha', '{}')",
  );
}

Future<int> _count(AppDatabase db, String table) async {
  final QueryRow row = await db
      .customSelect('SELECT COUNT(*) AS count FROM $table')
      .getSingle();
  return row.read<int>('count');
}

void _installVersion13Projects(Database database) {
  database.execute('''
CREATE TABLE projects (
  id TEXT NOT NULL PRIMARY KEY,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  updated_by_device TEXT NOT NULL,
  rev INTEGER NOT NULL DEFAULT 1,
  name TEXT NOT NULL,
  client TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL,
  started_at INTEGER NULL,
  completed_at INTEGER NULL,
  folder_name TEXT NOT NULL,
  settings TEXT NOT NULL
)
''');
  database.execute(
    'CREATE INDEX projects_by_status ON projects (status, updated_at)',
  );
  final int older = DateTime.utc(2026, 9, 17, 8).millisecondsSinceEpoch;
  final int newer = DateTime.utc(2026, 9, 17, 9).millisecondsSinceEpoch;
  database.execute('''
INSERT INTO projects (
  id, created_at, updated_at, updated_by_device, rev,
  name, client, status, folder_name, settings
) VALUES (
  'alpha', $older, $older, 'device-a', 3,
  'Alpha', 'Acme', 'active', 'alpha-1', '{}'
)
''');
  database.execute('''
INSERT INTO projects (
  id, created_at, updated_at, updated_by_device, rev,
  name, client, status, folder_name, settings
) VALUES (
  'beta', $newer, $newer, 'device-a', 1,
  'Beta', 'Acme', 'active', 'beta-1', '{}'
)
''');
  database.execute('PRAGMA user_version = 13');
}

Future<void> _expectVersion14Projects(AppDatabase db) async {
  await _expectVersion14Schema(db);
  final List<Project> rows = await db.select(db.projects).get();
  expect(rows, hasLength(2));
  expect(rows.map((Project row) => row.id).toSet(), <String>{'alpha', 'beta'});
  expect(rows.every((Project row) => row.pinnedAt == null), isTrue);
  final Project alpha = rows.firstWhere((Project row) => row.id == 'alpha');
  expect(alpha.name, 'Alpha');
  expect(alpha.rev, 3);
  expect(alpha.updatedByDevice, 'device-a');
  expect(alpha.folderName, 'alpha-1');
}

Future<void> _expectVersion14Schema(AppDatabase db) async {
  final Set<String> columns = (await _columnSets(db))['projects']!;
  expect(columns, contains('pinned_at'));
  final List<QueryRow> indexes = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name = 'projects_by_status_pin'",
      )
      .get();
  expect(indexes, hasLength(1));
}
