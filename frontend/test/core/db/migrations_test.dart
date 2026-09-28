import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/migrations.dart';
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/errors/failure.dart';

import 'record_rows.dart';

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
    'version 19 keeps an existing photo as an original and can run twice',
    () async {
      expect(kDestructiveSteps.contains(19), isFalse);
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.customStatement('ALTER TABLE photos DROP COLUMN derived_from');
      await db.customStatement(
        'ALTER TABLE photos DROP COLUMN rotation_degrees',
      );
      await _insertProject(db);
      await db.customStatement(
        'INSERT INTO photos '
        '(id, created_at, updated_at, updated_by_device, rev, project_id, '
        'capture_session_id, original_filename, stored_filename, relative_path, '
        'photo_type, sort_order, width, height, file_size, mime_type, sha256, '
        'captured_at) '
        "VALUES ('photo-1', 1, 1, 'device-1', 1, 'project-1', 'session-1', "
        "'IMG.jpg', 'photo-1.jpg', 'photos/photo-1.jpg', 'front', 0, 2, 2, "
        "4, 'image/jpeg', 'hash-1', 1)",
      );

      await migrateToV19(Migrator(db), db);
      await migrateToV19(Migrator(db), db);

      final Photo photo = await db.select(db.photos).getSingle();
      expect(photo.derivedFrom, isNull);
      expect(photo.rotationDegrees, isNull);
      expect(photo.sha256, 'hash-1');
      expect(await _count(db, 'photos'), 1);
    },
  );

  test('version 20 keeps three context levels and copies field keys', () async {
    expect(kDestructiveSteps.contains(20), isFalse);
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();
    await db.customStatement(
      'INSERT INTO context_definitions '
      '(id, created_at, updated_at, updated_by_device, rev, project_id, '
      'level, field_key, label) VALUES '
      "('c1', 1, 1, 'device-1', 1, 'project-1', 1, 'district', 'District'), "
      "('c2', 1, 1, 'device-1', 1, 'project-1', 2, 'facility', 'Facility'), "
      "('c3', 1, 1, 'device-1', 1, 'project-1', 3, 'ward', 'Ward')",
    );
    await db.customStatement(
      'INSERT INTO context_state '
      '(id, created_at, updated_at, updated_by_device, rev, project_id, '
      "level, field_key, value, set_at) VALUES "
      "('s1', 1, 1, 'device-1', 1, 'project-1', 1, '', 'North', 1)",
    );

    await migrateToV20(Migrator(db), db);
    await migrateToV20(Migrator(db), db);

    expect(await _count(db, 'context_definitions'), 3);
    final ContextStateRow state = await db.select(db.contextState).getSingle();
    expect(state.fieldKey, 'district');
    expect(state.value, 'North');
  });

  test(
    'version 21 normalises statuses, numbers records per project in capture order, builds the search index and can run twice',
    () async {
      expect(kDestructiveSteps.contains(21), isFalse);
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await _unwindVersion21(db);
      final Set<String> recordColumns = (await _columnSets(db))['records']!;
      expect(recordColumns.contains('record_number'), isFalse);

      await _legacyRecord(db, 'a', projectId: 'p1', status: 'CAPTURED', at: 30);
      await _legacyRecord(
        db,
        'b',
        projectId: 'p1',
        status: 'NEEDS_REVIEW',
        at: 10,
      );
      await _legacyRecord(
        db,
        'd',
        projectId: 'p1',
        status: 'EXTRACTED',
        at: 20,
      );
      await _legacyRecord(
        db,
        'c',
        projectId: 'p1',
        status: 'needs_review',
        at: 20,
      );
      await _legacyRecord(db, 'e', projectId: 'p2', status: 'approved', at: 5);
      await seedRow(db, 'record_fields', <String, Object?>{
        'id': 'f1',
        'record_id': 'a',
        'field_key': 'model',
        'value_raw': 'Grundfos CR-45',
        'source': 'ocr',
      });
      await seedCaption(
        db,
        'c1',
        ownerType: 'record',
        ownerId: 'b',
        text: 'Rusted valve',
      );
      await seedPhoto(db, 'ph1', recordId: 'e', projectId: 'p2', sha256: 'h1');
      await seedRow(db, 'ocr_cache', <String, Object?>{
        'id': 'o1',
        'content_hash': 'h1',
        'perceptual_hash': '00',
        'recognised_text': 'SERIAL 99-ALPHA',
        'blocks_json': '[]',
      });
      expect(await statusOf(db, 'a'), 'CAPTURED');
      final Map<String, int> before = await _rowCounts(db);

      await migrateToV21(Migrator(db), db);
      await migrateToV21(Migrator(db), db);

      final Map<String, Set<String>> columns = await _columnSets(db);
      expect(columns['records'], contains('record_number'));
      expect(
        columns['record_fields'],
        containsAll(<String>['evidence_removed_at', 'retired_at']),
      );
      final Map<String, int> after = await _rowCounts(db);
      for (final String table in <String>[
        'records',
        'record_fields',
        'captions',
        'photos',
        'ocr_cache',
        'audit_log',
      ]) {
        expect(after[table], before[table], reason: table);
      }
      expect(after['record_search_docs'], 5);
      expect(after['record_search'], 5);

      expect(await statusOf(db, 'a'), 'captured');
      expect(await statusOf(db, 'b'), 'needsReview');
      expect(await statusOf(db, 'c'), 'needsReview');
      expect(await statusOf(db, 'd'), 'extracted');
      expect(await statusOf(db, 'e'), 'approved');

      expect(await numberOf(db, 'b'), 1);
      expect(await numberOf(db, 'c'), 2);
      expect(await numberOf(db, 'd'), 3);
      expect(await numberOf(db, 'a'), 4);
      expect(await numberOf(db, 'e'), 1);

      expect(await searchRecords(db, 'grundfos'), <String>['a']);
      expect(await searchRecords(db, 'rusted'), <String>['b']);
      expect(await searchRecords(db, '99-alpha'), <String>['e']);

      await _legacyRecord(db, 'f', projectId: 'p1', status: 'FAILED', at: 1);
      expect(await numberOf(db, 'f'), 5);
      expect(await statusOf(db, 'f'), 'failed');
      expect((await searchDoc(db, 'f'))?.projectId, 'p1');

      final List<QueryRow> objects = await db
          .customSelect('SELECT name FROM sqlite_master')
          .get();
      final Set<String> names = <String>{
        for (final QueryRow row in objects) row.read<String>('name'),
      };
      expect(names, containsAll(RecordSchema.indexNames));
      expect(names, containsAll(RecordSchema.triggerNames));
      expect(names, contains(RecordSchema.searchSourceView));
    },
  );

  test(
    'an upgraded version 1 file and a fresh database hold the same indexes, triggers and views',
    () async {
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_migrate_schema_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });
      _seedVersion1(File('${directory.path}/tapture.sqlite'));
      final AppDatabase upgraded = AppDatabase.open(
        directoryPath: directory.path,
      );
      await upgraded.customSelect('SELECT 1').get();
      final Set<String> upgradedSchema = await _schemaObjects(upgraded);
      await upgraded.close();

      final AppDatabase fresh = AppDatabase.memory();
      addTearDown(fresh.close);
      await fresh.customSelect('SELECT 1').get();

      expect(upgradedSchema, await _schemaObjects(fresh));
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

  test('version 22 adds destinations and can run twice', () async {
    expect(kDestructiveSteps.contains(22), isFalse);
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    await migrateToV22(Migrator(db), db);
    await migrateToV22(Migrator(db), db);
    expect((await _columnSets(db)).containsKey('destinations'), isTrue);
    expect((await _columnSets(db))['destinations'], contains('credential_ref'));
  });

  test(
    'version 23 lets a confirmed reference key repeat, keeps the rows and can run twice',
    () async {
      expect(kDestructiveSteps.contains(23), isFalse);
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      // A version 22 device held the key index as unique.
      await db.customStatement('DROP INDEX reference_rows_by_key');
      await db.customStatement(
        'CREATE UNIQUE INDEX reference_rows_by_key '
        'ON reference_rows (dataset_id, key_value)',
      );
      await _insertReferenceRow(db, 'row-1');
      await expectLater(_insertReferenceRow(db, 'row-2'), throwsA(anything));

      await migrateToV23(Migrator(db), db);
      await migrateToV23(Migrator(db), db);

      expect(await _count(db, 'reference_rows'), 1);
      await _insertReferenceRow(db, 'row-2');
      expect(await _count(db, 'reference_rows'), 2);
      final List<QueryRow> indexes = await db
          .customSelect("PRAGMA index_list('reference_rows')")
          .get();
      final QueryRow byKey = indexes.singleWhere(
        (QueryRow row) => row.read<String>('name') == 'reference_rows_by_key',
      );
      expect(byKey.read<int>('unique'), 0);
    },
  );

  test(
    'version 24 keeps each record on its template current version and can run twice',
    () async {
      expect(kDestructiveSteps.contains(24), isFalse);
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.customStatement(
        'ALTER TABLE records DROP COLUMN template_version',
      );
      expect(
        (await _columnSets(db))['records']!.contains('template_version'),
        isFalse,
      );
      await seedRow(db, 'templates', <String, Object?>{
        'id': 't1',
        'name': 'Pump',
        'kind': 'equipment',
        'source': 'built',
        'version': 3,
      });
      await seedRecord(db, 'r1');
      await seedRecord(db, 'r2', templateId: 't-gone');

      await migrateToV24(Migrator(db), db);
      await migrateToV24(Migrator(db), db);

      expect(await _count(db, 'records'), 2);
      expect(await _templateVersionOf(db, 'r1'), 3);
      expect(await _templateVersionOf(db, 'r2'), 1);
    },
  );
}

/// Inserts reference row [id] of dataset `ds-1` under the key `K1`.
Future<void> _insertReferenceRow(AppDatabase db, String id) {
  return db.customStatement(
    'INSERT INTO reference_rows '
    '(id, created_at, updated_at, updated_by_device, rev, dataset_id, '
    'key_value, key_normalised, "values") '
    "VALUES (?, 1, 1, 'device-1', 1, 'ds-1', 'K1', 'k1', '{}')",
    <Object?>[id],
  );
}

Future<int> _templateVersionOf(AppDatabase db, String recordId) async {
  final QueryRow row = await db
      .customSelect(
        'SELECT template_version FROM records WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>(recordId)],
      )
      .getSingle();
  return row.read<int>('template_version');
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

/// Every index, trigger and view with the SQL that made it, plus every
/// table, so the two paths to head can be compared exactly.
Future<Set<String>> _schemaObjects(AppDatabase db) async {
  final List<QueryRow> rows = await db
      .customSelect(
        "SELECT type, name, tbl_name, sql FROM sqlite_master "
        "WHERE name NOT LIKE 'sqlite_%'",
      )
      .get();
  return <String>{
    for (final QueryRow row in rows)
      <String>[
        row.read<String>('type'),
        row.read<String>('name'),
        row.read<String>('tbl_name'),
        if (row.read<String>('type') != 'table') row.read<String?>('sql') ?? '',
      ].join(' | '),
  };
}

/// Returns a head database to its version 20 shape: no version 21 columns,
/// indexes, triggers, view or search tables.
Future<void> _unwindVersion21(AppDatabase db) async {
  for (final String trigger in RecordSchema.triggerNames) {
    await db.customStatement('DROP TRIGGER IF EXISTS $trigger');
  }
  await db.customStatement(
    'DROP VIEW IF EXISTS ${RecordSchema.searchSourceView}',
  );
  await db.customStatement('DROP TABLE IF EXISTS ${RecordSchema.searchTable}');
  await db.customStatement(
    'DROP TABLE IF EXISTS ${RecordSchema.searchDocsTable}',
  );
  for (final String index in RecordSchema.indexNames) {
    await db.customStatement('DROP INDEX IF EXISTS $index');
  }
  await db.customStatement('ALTER TABLE records DROP COLUMN record_number');
  await db.customStatement(
    'ALTER TABLE record_fields DROP COLUMN evidence_removed_at',
  );
  await db.customStatement('ALTER TABLE record_fields DROP COLUMN retired_at');
}

/// A record row as a version 20 device stored it: no number, and any status
/// spelling.
Future<void> _legacyRecord(
  AppDatabase db,
  String id, {
  required String projectId,
  required String status,
  required int at,
}) {
  return seedRow(db, 'records', <String, Object?>{
    'id': id,
    'project_id': projectId,
    'template_id': 't1',
    'status': status,
    'processing_mode': 'manual',
    'context_json': '{}',
    'identity_hash': 'hash-$id',
    'source': 'capture',
    'captured_at': at,
    'captured_by': 'device-a',
  });
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
