import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/migrations.dart';
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/merge.dart';
import 'package:tapture/core/db/tables/processing.dart';
import 'package:tapture/core/db/version_vector_schema.dart';
import 'package:tapture/core/errors/failure.dart';

import 'record_rows.dart';

/// The versions a step test was declared for, filled while [main] declares
/// the tests and read by the first test once they run.
final Set<int> _stepsTested = <int>{};

/// The newest schema this suite's step tests were written against. A step
/// past it has no test until one is declared with [_stepTest].
const int _releasedHead = 33;

/// Declares a test of the migration step to [version]. Every step must have
/// one: typing a number into another test's title does not count.
void _stepTest(int version, String description, Future<void> Function() body) {
  _stepsTested.add(version);
  test('version $version: $description', body);
}

void main() {
  tearDown(clearExportAcknowledgement);

  _stepTest(
    33,
    'installs the transcript version-vector triggers, seeds the clocks of '
    'transcripts already written, keeps every row and can run twice',
    () async {
      expect(kSchemaVersion, 33);
      expect(kDestructiveSteps, isEmpty);
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      const List<String> triggers = <String>[
        'vector_transcripts_insert',
        'vector_transcripts_update',
        'vector_transcript_segments_insert',
        'vector_transcript_segments_update',
      ];
      for (final String trigger in triggers) {
        await db.customStatement('DROP TRIGGER $trigger');
      }
      await seedRow(db, 'transcripts', <String, Object?>{
        'id': 't1',
        'project_id': 'p1',
        'owner_kind': 'standalone',
        'audio_path': 'projects/alpha/audio/t1.wav',
        'language_tag': 'en',
        'model_id': 'tiny-q5_1',
        'status': 'complete',
        'started_at': 1,
        'rev': 2,
      });
      await seedRow(db, 'transcript_segments', <String, Object?>{
        'id': 's1',
        'transcript_id': 't1',
        'seq': 1,
        'start_ms': 0,
        'end_ms': 900,
        'text_raw': 'reservoir fencing',
      });
      final Map<String, int> before = await _rowCounts(db);
      expect(before['version_vectors'], 0);

      await migrateToV33(Migrator(db), db);
      final Set<String> once = await _schemaObjects(db);
      final Map<String, int> afterOnce = await _rowCounts(db);
      await migrateToV33(Migrator(db), db);
      expect(await _schemaObjects(db), once);
      expect(await _rowCounts(db), afterOnce);

      expect(<String>{
        for (final QueryRow row
            in await db
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'trigger'",
                )
                .get())
          row.read<String>('name'),
      }, containsAll(triggers));
      expect(afterOnce['transcripts'], 1);
      expect(afterOnce['transcript_segments'], 1);
      final List<QueryRow> clocks = await db
          .customSelect(
            'SELECT entity_type, entity_id, device_id, seen_rev '
            'FROM version_vectors ORDER BY entity_type',
          )
          .get();
      expect(
        <String>[
          for (final QueryRow row in clocks)
            '${row.read<String>('entity_type')}/'
                '${row.read<String>('entity_id')}/'
                '${row.read<String>('device_id')}='
                '${row.read<int>('seen_rev')}',
        ],
        <String>[
          'transcript_segments/s1/device-a=1',
          'transcripts/t1/device-a=2',
        ],
      );
    },
  );

  _stepTest(
    32,
    'adds transcripts and segments with their indexes, keeps every row, '
    'rebuilds search documents and can run twice',
    () async {
      expect(kDestructiveSteps, isEmpty);
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await seedRecord(db, 'r1');
      await seedField(
        db,
        'f1',
        recordId: 'r1',
        fieldKey: 'model',
        raw: 'Grundfos',
      );
      await seedRow(db, 'attachments', <String, Object?>{
        'id': 'a1',
        'project_id': 'p1',
        'relative_path': 'audio/a1.wav',
        'mime_type': 'audio/wav',
        'file_size': 4,
        'sha256': 'hash-a1',
        'kind': 'audio',
      });
      await seedRow(db, 'attachment_owners', <String, Object?>{
        'id': 'o1',
        'attachment_id': 'a1',
        'owner_type': 'record',
        'owner_id': 'r1',
      });
      await _unwindVersion32(db);
      final Map<String, int> before = await _rowCounts(db);
      expect(before.containsKey('transcripts'), isFalse);
      expect(before.containsKey('transcript_segments'), isFalse);

      await migrateToV32(Migrator(db), db);
      final Set<String> once = await _schemaObjects(db);
      await migrateToV32(Migrator(db), db);
      expect(await _schemaObjects(db), once);

      final Map<String, int> after = await _rowCounts(db);
      for (final String table in <String>[
        'records',
        'record_fields',
        'attachments',
        'attachment_owners',
        'audit_log',
      ]) {
        expect(after[table], before[table], reason: table);
      }
      expect(after['transcripts'], 0);
      expect(after['transcript_segments'], 0);
      expect(after['record_search'], 1);
      expect(await searchRecords(db, 'grundfos'), <String>['r1']);
      final Set<String> names = <String>{
        for (final QueryRow row
            in await db.customSelect('SELECT name FROM sqlite_master').get())
          row.read<String>('name'),
      };
      expect(
        names,
        containsAll(<String>[
          'transcripts_by_project',
          'transcripts_by_attachment',
          'transcripts_by_owner',
          'transcript_segments_by_transcript',
          ...RecordSchema.triggerNames,
        ]),
      );

      // The rebuilt triggers index a finished transcript of the record's
      // audio.
      await seedRow(db, 'transcripts', <String, Object?>{
        'id': 't1',
        'project_id': 'p1',
        'owner_kind': 'capture',
        'attachment_id': 'a1',
        'audio_path': 'projects/alpha/audio/a1.wav',
        'language_tag': 'en',
        'model_id': 'tiny-q5_1',
        'status': 'live',
        'started_at': 1,
      });
      await seedRow(db, 'transcript_segments', <String, Object?>{
        'id': 's1',
        'transcript_id': 't1',
        'seq': 1,
        'start_ms': 0,
        'end_ms': 900,
        'text_raw': 'reservoir fencing',
      });
      expect(await searchRecords(db, 'reservoir'), isEmpty);
      await db.customStatement(
        "UPDATE transcripts SET status = 'complete' WHERE id = 't1'",
      );
      expect(await searchRecords(db, 'reservoir'), <String>['r1']);
    },
  );

  _stepTest(
    31,
    'adds semantic failures without rewriting previous error text or generations',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.customStatement(
        'ALTER TABLE processing_jobs DROP COLUMN last_error_message',
      );
      await seedRow(db, 'processing_jobs', <String, Object?>{
        'id': 'old-failure',
        'record_id': 'record',
        'stage': 'extract',
        'status': 'failed',
        'queued_at': 1,
        'attempts': 4,
        'request_generation': 3,
        'last_error': 'Keep this exact custom explanation.',
      });
      await migrateToV31(Migrator(db), db);
      await migrateToV31(Migrator(db), db);
      final ProcessingJobRow row = await db.select(db.processing).getSingle();
      expect(row.lastError, 'Keep this exact custom explanation.');
      expect(row.lastErrorMessage, isNull);
      expect(row.requestGeneration, 3);
      expect(row.attempts, 4);
      expect(row.status, ProcessingJobStatus.failed);
    },
  );

  _stepTest(
    30,
    'indexes tied failure pages and preserves queued retry state',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.customStatement('DROP INDEX processing_jobs_failures_page');
      for (final String id in <String>['c', 'a', 'b', 'queued']) {
        await seedRow(db, 'processing_jobs', <String, Object?>{
          'id': id,
          'record_id': 'record-$id',
          'stage': 'extract',
          'status': id == 'queued' ? 'queued' : 'failed',
          'queued_at': 1,
          'attempts': 2,
          'request_generation': 3,
          'last_error': 'Retained error',
        });
      }
      await migrateToV30(Migrator(db), db);
      await migrateToV30(Migrator(db), db);
      const String query =
          "SELECT id FROM processing_jobs WHERE status = 'failed' AND (queued_at, id) > (1, 'a') ORDER BY queued_at, id LIMIT 2";
      expect(
        (await db.customSelect(query).get()).map(
          (QueryRow row) => row.read<String>('id'),
        ),
        <String>['b', 'c'],
      );
      final List<QueryRow> plan = await db
          .customSelect('EXPLAIN QUERY PLAN $query')
          .get();
      expect(
        plan.map((QueryRow row) => row.read<String>('detail')).join(' '),
        contains('processing_jobs_failures_page'),
      );
      expect(await _count(db, 'processing_jobs'), 4);
      final QueryRow retained = await db
          .customSelect("SELECT * FROM processing_jobs WHERE id = 'queued'")
          .getSingle();
      expect(retained.read<String>('status'), 'queued');
      expect(retained.read<int>('request_generation'), 3);
      expect(retained.read<String>('last_error'), 'Retained error');
    },
  );

  _stepTest(
    29,
    'indexes pending undo intents without changing history',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.customStatement('DROP INDEX merge_sessions_pending_undo');
      for (final String id in <String>['old', 'pending']) {
        await seedRow(db, 'merge_sessions', <String, Object?>{
          'id': id,
          'bundle_name': 'project.zip',
          'source_device': 'other-device',
          'imported_at': 1,
          'counts': id == 'pending'
              ? '{"undo_journal":"snapshot.undo","records":3}'
              : '{"records":3}',
          'status': 'applied',
          'undo_snapshot_path': 'snapshot',
        });
      }
      await migrateToV29(Migrator(db), db);
      await migrateToV29(Migrator(db), db);
      const String query =
          'SELECT * FROM merge_sessions WHERE $mergePendingUndoWhere';
      expect(
        (await db.customSelect(query).get()).single.read<String>('id'),
        'pending',
      );
      final List<QueryRow> plan = await db
          .customSelect('EXPLAIN QUERY PLAN $query')
          .get();
      expect(
        plan.map((QueryRow row) => row.read<String>('detail')).join(' '),
        contains('USING INDEX merge_sessions_pending_undo'),
      );
      expect(await _count(db, 'merge_sessions'), 2);
      expect(
        (await db
                .customSelect(
                  "SELECT counts FROM merge_sessions WHERE id = 'old'",
                )
                .getSingle())
            .read<String>('counts'),
        '{"records":3}',
      );
    },
  );

  _stepTest(
    28,
    'adds retry generations without rewriting queued jobs',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.customStatement(
        'ALTER TABLE processing_jobs DROP COLUMN request_generation',
      );
      await seedRow(db, 'processing_jobs', <String, Object?>{
        'id': 'old-job',
        'record_id': 'record',
        'stage': 'extract',
        'status': 'failed',
        'attempts': 4,
        'queued_at': 1,
        'last_error': 'Previous response',
      });
      await migrateToV28(Migrator(db), db);
      await migrateToV28(Migrator(db), db);
      final QueryRow row = await db
          .customSelect(
            'SELECT * FROM processing_jobs WHERE id = ?',
            variables: <Variable<Object>>[const Variable<String>('old-job')],
          )
          .getSingle();
      expect(row.read<int>('request_generation'), 0);
      expect(row.read<int>('attempts'), 4);
      expect(row.read<String>('last_error'), 'Previous response');
    },
  );

  test('every schema version has a named upgrade step and its own test', () {
    expect(kUpgradeSteps.length, kSchemaVersion);
    for (int version = 1; version <= kSchemaVersion; version++) {
      expect(
        kUpgradeSteps.containsKey(version),
        isTrue,
        reason: 'schema version $version has no named upgrade step',
      );
      expect(
        _stepsTested,
        contains(version),
        reason:
            'schema version $version has no migration test; declare one '
            'with _stepTest($version, ...)',
      );
    }
  });

  for (int version = 2; version <= _releasedHead; version++) {
    _stepTest(
      version,
      'rows seeded at version ${version - 1} survive this step and every '
      'later one, and the schema reaches head',
      () async {
        final Database raw = sqlite3.openInMemory();
        raw.execute('PRAGMA user_version = 1');
        final AppDatabase older = _AtVersion(
          NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
          version - 1,
        );
        await older.customSelect('SELECT 1').get();
        final Map<String, String> seeded = await _seedEveryTable(older);
        await older.close();

        final AppDatabase head = AppDatabase(NativeDatabase.opened(raw));
        addTearDown(head.close);
        await head.customSelect('SELECT 1').get();
        final AppDatabase fresh = AppDatabase.memory();
        addTearDown(fresh.close);
        await fresh.customSelect('SELECT 1').get();

        expect(await _columnSets(head), await _columnSets(fresh));
        for (final MapEntry<String, String> row in seeded.entries) {
          final QueryRow count = await head
              .customSelect(
                'SELECT COUNT(*) AS n FROM "${row.key}" WHERE id = ?',
                variables: <Variable<Object>>[Variable<String>(row.value)],
              )
              .getSingle();
          expect(
            count.read<int>('n'),
            1,
            reason: '${row.key} lost its version ${version - 1} row',
          );
        }
      },
    );
  }

  _stepTest(
    1,
    'a seeded version 1 file upgrades to head with the columns and row counts of a fresh database',
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

  _stepTest(
    14,
    'a native version 13 file upgrades with its projects intact',
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
      raw.close();

      final AppDatabase upgraded = AppDatabase.open(
        directoryPath: directory.path,
      );
      addTearDown(upgraded.close);
      await upgraded.customSelect('SELECT 1').get();
      await _expectVersion14Projects(upgraded);
    },
  );

  _stepTest(
    14,
    'an in-memory version 13 database upgrades with its projects intact',
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

  _stepTest(
    14,
    'an interrupted upgrade leaves version 13 rows usable',
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

  _stepTest(
    17,
    'creates project-scoped capture sessions without changing projects',
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

  _stepTest(
    18,
    'creates attachment owners and preserves version 17 capture and attachment rows',
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

  _stepTest(
    19,
    'keeps an existing photo as an original and can run twice',
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

  _stepTest(20, 'keeps three context levels and copies field keys', () async {
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

  _stepTest(
    21,
    'normalises statuses, numbers records per project in capture order, builds the search index and can run twice',
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

  _stepTest(
    16,
    'is not a destructive step and a second run is a no-op',
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

  _stepTest(
    15,
    'is not a destructive step and a second run is a no-op',
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

  _stepTest(
    14,
    'is not a destructive step and a second run is a no-op',
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

  _stepTest(22, 'adds destinations and can run twice', () async {
    expect(kDestructiveSteps.contains(22), isFalse);
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    await migrateToV22(Migrator(db), db);
    await migrateToV22(Migrator(db), db);
    expect((await _columnSets(db)).containsKey('destinations'), isTrue);
    expect((await _columnSets(db))['destinations'], contains('credential_ref'));
  });

  _stepTest(
    23,
    'lets a confirmed reference key repeat, keeps the rows and can run twice',
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

  _stepTest(
    24,
    'keeps each record on its template current version and can run twice',
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

  _stepTest(
    25,
    'adds the record account columns empty, keeps every record and can run '
    'twice',
    () async {
      expect(kDestructiveSteps.contains(25), isFalse);
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.customStatement(
        'ALTER TABLE records DROP COLUMN captured_by_account',
      );
      await db.customStatement(
        'ALTER TABLE records DROP COLUMN approved_by_account',
      );
      await seedRecord(db, 'r1');

      await migrateToV25(Migrator(db), db);
      await migrateToV25(Migrator(db), db);

      expect(
        (await _columnSets(db))['records'],
        containsAll(<String>['captured_by_account', 'approved_by_account']),
      );
      expect(await _count(db, 'records'), 1);
      final QueryRow row = await db
          .customSelect(
            'SELECT captured_by, captured_by_account FROM records '
            "WHERE id = 'r1'",
          )
          .getSingle();
      expect(row.read<String?>('captured_by_account'), isNull);
      expect(row.read<String>('captured_by'), isNotEmpty);
    },
  );

  _stepTest(
    26,
    'lets a meeting action go undated, keeps every action and its index, '
    'and can run twice',
    () async {
      expect(kDestructiveSteps.contains(26), isFalse);
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.customStatement('DROP TABLE meeting_actions');
      await db.customStatement(
        'CREATE TABLE meeting_actions (id TEXT NOT NULL PRIMARY KEY, '
        'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
        'updated_by_device TEXT NOT NULL, rev INTEGER NOT NULL DEFAULT 1, '
        'meeting_id TEXT NOT NULL, "action" TEXT NOT NULL, '
        'owner_name TEXT NOT NULL, due_date INTEGER NOT NULL, '
        'status TEXT NOT NULL)',
      );
      await db.customStatement(
        'CREATE INDEX meeting_actions_by_meeting_status '
        'ON meeting_actions (meeting_id, status)',
      );
      await db.customStatement(
        'INSERT INTO meeting_actions (id, created_at, updated_at, '
        'updated_by_device, rev, meeting_id, "action", owner_name, due_date, '
        "status) VALUES ('a1', 1, 1, 'device-1', 1, 'm1', 'Paint the gate', "
        "'Ada', 1, 'open')",
      );

      await migrateToV26(Migrator(db), db);
      await migrateToV26(Migrator(db), db);

      await db.customStatement(
        'INSERT INTO meeting_actions (id, created_at, updated_at, '
        'updated_by_device, rev, meeting_id, "action", owner_name, due_date, '
        "status) VALUES ('a2', 1, 1, 'device-1', 1, 'm1', 'Book the room', "
        "'', NULL, 'open')",
      );
      expect(await _count(db, 'meeting_actions'), 2);
      final List<QueryRow> indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name = 'meeting_actions_by_meeting_status'",
          )
          .get();
      expect(indexes, hasLength(1));
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

/// The app database stopped at [_version]: opening a version 1 file runs the
/// real steps up to it and no further, the shape a device on that release
/// holds.
final class _AtVersion extends AppDatabase {
  _AtVersion(super.e, this._version);

  final int _version;

  @override
  int get schemaVersion => _version;
}

/// One representative row in every table [db] holds, each column filled by
/// its type, and each row's id by table. Derived search tables are left to
/// the triggers that fill them.
Future<Map<String, String>> _seedEveryTable(AppDatabase db) async {
  final List<QueryRow> tables = await db
      .customSelect(
        "SELECT name, sql FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      )
      .get();
  final Map<String, String> seeded = <String, String>{};
  for (final QueryRow table in tables) {
    final String name = table.read<String>('name');
    final String sql = table.read<String?>('sql') ?? '';
    if (sql.toUpperCase().startsWith('CREATE VIRTUAL') ||
        name.startsWith(RecordSchema.searchTable) ||
        name == VersionVectorSchema.holdTable) {
      continue;
    }
    final List<QueryRow> columns = await db
        .customSelect('PRAGMA table_info("$name")')
        .get();
    final Map<String, Object?> row = <String, Object?>{};
    for (final QueryRow column in columns) {
      final String columnName = column.read<String>('name');
      final String type = (column.read<String?>('type') ?? '').toUpperCase();
      if (columnName == 'id') {
        row[columnName] = 'seed-$name';
      } else if (type.contains('INT')) {
        row[columnName] = 1;
      } else if (type.contains('REAL')) {
        row[columnName] = 1.5;
      } else if (type.contains('BLOB')) {
        row[columnName] = Uint8List.fromList(<int>[0]);
      } else {
        row[columnName] = '{}';
      }
    }
    if (!row.containsKey('id')) {
      continue;
    }
    if (name == 'version_vectors') {
      // Authored-row triggers may have populated vectors while seeding.
      // Give the explicit migration fixture an independent causal identity.
      row['entity_type'] = 'records';
      row['entity_id'] = 'seed-vector-entity';
      row['device_id'] = 'seed-vector-device';
    }
    final List<String> names = row.keys.toList();
    await db.customStatement(
      'INSERT INTO "$name" '
      '(${names.map((String column) => '"$column"').join(', ')}) '
      'VALUES (${List<String>.filled(names.length, '?').join(', ')})',
      <Object?>[for (final String column in names) row[column]],
    );
    seeded[name] = 'seed-$name';
  }
  return seeded;
}

void _seedVersion1(File file) {
  file.parent.createSync(recursive: true);
  final Database database = sqlite3.open(file.path);
  database.execute('PRAGMA user_version = 1');
  database.close();
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

/// Returns a head database to its version 31 shape: no transcript tables,
/// their indexes or their search triggers, and an empty search index.
Future<void> _unwindVersion32(AppDatabase db) async {
  for (final String trigger in <String>[
    'transcripts_search_ai',
    'transcripts_search_au',
    'transcripts_search_ad',
    'attachment_owners_search_ai',
    'attachment_owners_search_ad',
  ]) {
    await db.customStatement('DROP TRIGGER IF EXISTS $trigger');
  }
  await db.customStatement(
    'DROP VIEW IF EXISTS ${RecordSchema.searchSourceView}',
  );
  await db.customStatement('DROP TABLE transcript_segments');
  await db.customStatement('DROP TABLE transcripts');
  await db.customStatement('DELETE FROM ${RecordSchema.searchTable}');
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
