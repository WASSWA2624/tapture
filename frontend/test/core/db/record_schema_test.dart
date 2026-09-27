import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';

import 'record_rows.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  group('stored status', () {
    test('the canonical list is RecordStatus by name and in order', () {
      expect(RecordSchema.statusNames, <String>[
        for (final RecordStatus status in RecordStatus.values) status.name,
      ]);
    });

    test('a legacy spelling is rewritten when the row is inserted', () async {
      await seedRecord(db, 'r1', status: 'NEEDS_REVIEW');
      await seedRecord(db, 'r2', status: 'CAPTURED');
      await seedRecord(db, 'r3', status: 'needs_review');
      await seedRecord(db, 'r4', status: 'Approved');
      await seedRecord(db, 'r5', status: 'needsReview');
      await seedRecord(db, 'r6', status: 'something-else');

      expect(await statusOf(db, 'r1'), 'needsReview');
      expect(await statusOf(db, 'r2'), 'captured');
      expect(await statusOf(db, 'r3'), 'needsReview');
      expect(await statusOf(db, 'r4'), 'approved');
      expect(await statusOf(db, 'r5'), 'needsReview');
      expect(await statusOf(db, 'r6'), 'something-else');
    });

    test(
      'a legacy spelling is rewritten when the status is updated, without a revision bump',
      () async {
        await seedRecord(db, 'r1');
        await db.customStatement(
          "UPDATE records SET status = 'EXTRACTED' WHERE id = 'r1'",
        );
        expect(await statusOf(db, 'r1'), 'extracted');
        final QueryRow row = await db
            .customSelect("SELECT rev FROM records WHERE id = 'r1'")
            .getSingle();
        expect(row.read<int>('rev'), 1);
      },
    );

    test(
      'a record written through the table helper reads back canonical',
      () async {
        final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 17, 8));
        final RecordRow row = _ok(
          await upsertRecord(
            db,
            row: RecordsCompanion(
              projectId: const Value<String>('p1'),
              templateId: const Value<String>('t1'),
              status: const Value<String>('CAPTURED'),
              processingMode: const Value<String>('manual'),
              contextJson: const Value<String>('{}'),
              identityHash: const Value<String>('h1'),
              source: const Value<String>('capture'),
              capturedAt: Value<DateTime>(clock.nowUtc()),
              capturedBy: const Value<String>('device-a'),
            ),
            clock: clock,
            deviceId: 'device-a',
            ids: UuidV7Service.sequence(clock),
          ),
        );
        expect(row.status, 'captured');
        expect(row.recordNumber, 1);
      },
    );

    test('the SQL canonical expression folds the same way as Dart', () async {
      for (final String raw in <String>[
        'NEEDS_REVIEW',
        'needs_review',
        'Deleted',
        'unknown',
      ]) {
        final QueryRow row = await db
            .customSelect(
              'SELECT ${RecordSchema.canonicalExpression('?')} AS s',
              variables: <Variable<Object>>[
                Variable<String>(raw),
                Variable<String>(raw),
              ],
            )
            .getSingle();
        expect(row.read<String>('s'), canonicalRecordStatus(raw), reason: raw);
      }
    });
  });

  group('record number', () {
    test('numbers are allocated per project in insert order', () async {
      await seedRecord(db, 'a1', projectId: 'p1');
      await seedRecord(db, 'a2', projectId: 'p1');
      await seedRecord(db, 'b1', projectId: 'p2');
      await seedRecord(db, 'a3', projectId: 'p1');
      await seedRecord(db, 'b2', projectId: 'p2');

      expect(await numberOf(db, 'a1'), 1);
      expect(await numberOf(db, 'a2'), 2);
      expect(await numberOf(db, 'a3'), 3);
      expect(await numberOf(db, 'b1'), 1);
      expect(await numberOf(db, 'b2'), 2);
    });

    test(
      'a number that travelled with the row is kept and the next one follows it',
      () async {
        await seedRecord(db, 'r1', number: 7);
        await seedRecord(db, 'r2', number: 7);
        await seedRecord(db, 'r3');

        expect(await numberOf(db, 'r1'), 7);
        expect(await numberOf(db, 'r2'), 7);
        expect(await numberOf(db, 'r3'), 8);
      },
    );

    test('the number list is served by records_by_project_number', () async {
      final List<QueryRow> plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT id FROM records '
            "WHERE project_id = 'p1' ORDER BY record_number DESC, id DESC",
          )
          .get();
      expect(
        plan.map((QueryRow row) => row.read<String>('detail')).join('; '),
        contains('records_by_project_number'),
      );
    });
  });

  group('search document', () {
    test(
      'a value is found after insert and gone after its tombstone',
      () async {
        await seedRecord(db, 'r1');
        await seedRecord(db, 'r2');
        await seedField(
          db,
          'f1',
          recordId: 'r1',
          fieldKey: 'model',
          raw: 'Grundfos CR-45',
        );

        expect(await searchRecords(db, 'grundfos'), <String>['r1']);
        expect(await searchRecords(db, 'cr-4'), <String>['r1']);
        expect(await searchRecords(db, 'grundfos cr-45'), <String>['r1']);
        expect(await searchRecords(db, 'grundfos wilo'), isEmpty);

        await writeTombstone(
          db,
          entityType: 'record_fields',
          entityId: 'f1',
          reason: 'removed',
        );
        expect(await searchRecords(db, 'grundfos'), isEmpty);

        await removeTombstone(db, entityType: 'record_fields', entityId: 'f1');
        expect(await searchRecords(db, 'grundfos'), <String>['r1']);
      },
    );

    test(
      'an edited value is found under its new text and still under its raw text',
      () async {
        final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 17, 8));
        await seedRecord(db, 'r1');
        await seedField(
          db,
          'f1',
          recordId: 'r1',
          fieldKey: 'model',
          raw: 'Grundfos',
        );
        _ok(
          await writeRecordFieldRefined(
            db,
            id: 'f1',
            valueRefined: 'Wilo Stratos',
            clock: clock,
            deviceId: 'device-a',
            ids: UuidV7Service.sequence(clock),
          ),
        );
        expect(await searchRecords(db, 'stratos'), <String>['r1']);
        expect(await searchRecords(db, 'grundfos'), <String>['r1']);

        _ok(
          await writeRecordFieldFinal(
            db,
            id: 'f1',
            valueFinal: 'Xylem',
            clock: clock,
            deviceId: 'device-a',
            ids: UuidV7Service.sequence(clock),
          ),
        );
        expect(await searchRecords(db, 'xylem'), <String>['r1']);
      },
    );

    test(
      'captions of the record and of its live photos are found, refined text first',
      () async {
        await seedRecord(db, 'r1');
        await seedPhoto(db, 'ph1', recordId: 'r1');
        await seedCaption(
          db,
          'c1',
          ownerType: 'record',
          ownerId: 'r1',
          text: 'Rusted valve',
        );
        await seedCaption(
          db,
          'c2',
          ownerType: 'photo',
          ownerId: 'ph1',
          text: 'Nameplate close-up',
        );
        expect(await searchRecords(db, 'rusted'), <String>['r1']);
        expect(await searchRecords(db, 'nameplate'), <String>['r1']);

        await db.customStatement(
          "UPDATE captions SET text_refined = 'Corroded valve' WHERE id = 'c1'",
        );
        expect(await searchRecords(db, 'corroded'), <String>['r1']);
        expect(await searchRecords(db, 'rusted'), isEmpty);

        await writeTombstone(
          db,
          entityType: 'captions',
          entityId: 'c2',
          reason: 'removed',
        );
        expect(await searchRecords(db, 'nameplate'), isEmpty);
      },
    );

    test(
      'OCR text of a live photo is found, and a photo tombstone drops its OCR and caption until it is lifted',
      () async {
        await seedRecord(db, 'r1');
        await seedPhoto(db, 'ph1', recordId: 'r1', sha256: 'abc');
        await seedCaption(
          db,
          'c1',
          ownerType: 'photo',
          ownerId: 'ph1',
          text: 'Pump housing',
        );
        await seedRow(db, 'ocr_cache', <String, Object?>{
          'id': 'o1',
          'content_hash': 'abc',
          'perceptual_hash': '00',
          'recognised_text': 'SERIAL 99-ALPHA',
          'blocks_json': '[]',
        });
        expect(await searchRecords(db, '99-alpha'), <String>['r1']);

        await writeTombstone(
          db,
          entityType: 'photos',
          entityId: 'ph1',
          reason: 'removed',
        );
        expect(await searchRecords(db, '99-alpha'), isEmpty);
        expect(await searchRecords(db, 'housing'), isEmpty);

        await removeTombstone(db, entityType: 'photos', entityId: 'ph1');
        expect(await searchRecords(db, '99-alpha'), <String>['r1']);
        expect(await searchRecords(db, 'housing'), <String>['r1']);
      },
    );

    test(
      'a photo filed later brings its OCR text to the record it lands on',
      () async {
        await seedRecord(db, 'r1');
        await seedRecord(db, 'r2');
        await seedRow(db, 'ocr_cache', <String, Object?>{
          'id': 'o1',
          'content_hash': 'abc',
          'perceptual_hash': '00',
          'recognised_text': 'Kilowatt meter',
          'blocks_json': '[]',
        });
        await seedPhoto(db, 'ph1', recordId: null, sha256: 'abc');
        expect(await searchRecords(db, 'kilowatt'), isEmpty);

        await db.customStatement(
          "UPDATE photos SET record_id = 'r1' WHERE id = 'ph1'",
        );
        expect(await searchRecords(db, 'kilowatt'), <String>['r1']);

        await db.customStatement(
          "UPDATE photos SET record_id = 'r2' WHERE id = 'ph1'",
        );
        expect(await searchRecords(db, 'kilowatt'), <String>['r2']);
      },
    );

    test(
      'a stored transcript is found and another provider response is not',
      () async {
        await seedRecord(db, 'r1');
        await seedRow(db, 'processing_jobs', <String, Object?>{
          'id': 'j1',
          'record_id': 'r1',
          'stage': 'online',
          'status': 'running',
          'queued_at': 1,
        });
        await seedRow(db, 'processing_results', <String, Object?>{
          'id': 'pr1',
          'job_id': 'j1',
          'request_summary':
              '{"kind":"transcript","attachmentId":"a1","provider":"x"}',
          'raw_response': 'The borehole pump was replaced in March',
          'parsed_ok': 1,
        });
        await seedRow(db, 'processing_results', <String, Object?>{
          'id': 'pr2',
          'job_id': 'j1',
          'request_summary': '{"kind":"extraction"}',
          'raw_response': '{"fields":{"secretword":"zebra"}}',
          'parsed_ok': 1,
        });
        await seedRow(db, 'processing_results', <String, Object?>{
          'id': 'pr3',
          'job_id': 'j1',
          'request_summary': 'not json at all',
          'raw_response': 'plain response',
          'parsed_ok': 1,
        });
        expect(await searchRecords(db, 'borehole'), <String>['r1']);
        expect(await searchRecords(db, 'zebra'), isEmpty);
        expect(await searchRecords(db, 'plain'), isEmpty);
      },
    );

    test('a meeting transcript and its minutes are found', () async {
      await seedRecord(db, 'r1');
      await seedRow(db, 'meetings', <String, Object?>{
        'id': 'm1',
        'record_id': 'r1',
        'title': 'Site meeting',
        'start_at': 1,
        'agenda': '[]',
        'transcript_raw': 'We agreed to fence the reservoir',
      });
      expect(await searchRecords(db, 'reservoir'), <String>['r1']);
      await db.customStatement(
        "UPDATE meetings SET minutes_refined = 'Fencing approved' "
        "WHERE id = 'm1'",
      );
      expect(await searchRecords(db, 'fencing'), <String>['r1']);
    });

    test(
      'a deleted record keeps its document, and a removed row loses it',
      () async {
        final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 17, 8));
        await seedRecord(db, 'r1');
        await seedField(
          db,
          'f1',
          recordId: 'r1',
          fieldKey: 'model',
          raw: 'Grundfos',
        );
        await db.transaction(() async {
          await writeRecordStatus(
            db,
            recordId: 'r1',
            status: 'deleted',
            previousStatus: 'captured',
            clock: clock,
          );
          await writeTombstone(
            db,
            entityType: 'records',
            entityId: 'r1',
            reason: 'deleted by the operator',
            clock: clock,
          );
        });
        expect(await searchRecords(db, 'grundfos'), <String>['r1']);

        await db.customStatement("DELETE FROM records WHERE id = 'r1'");
        expect(await searchRecords(db, 'grundfos'), isEmpty);
        expect(await searchDoc(db, 'r1'), isNull);
        final QueryRow count = await db
            .customSelect('SELECT COUNT(*) AS n FROM record_search')
            .getSingle();
        expect(count.read<int>('n'), 0);
      },
    );

    test('a record moved to another project moves its document', () async {
      await seedRecord(db, 'r1');
      await db.customStatement(
        "UPDATE records SET project_id = 'p9' WHERE id = 'r1'",
      );
      expect((await searchDoc(db, 'r1'))?.projectId, 'p9');
    });

    test('a word shorter than three characters matches nothing', () async {
      await seedRecord(db, 'r1');
      await seedField(db, 'f1', recordId: 'r1', fieldKey: 'k', raw: 'ab cd');
      expect(await searchRecords(db, 'ab'), isEmpty);
    });
  });

  group('name and identifier', () {
    setUp(() async {
      await seedRow(db, 'templates', <String, Object?>{
        'id': 't1',
        'name': 'Equipment',
        'kind': 'asset',
        'source': 'built',
        'identity_fields': '["serial_number", "asset_tag"]',
      });
      await _templateField(db, 't1', 'record_uid', 0, inputMode: 'AUTO');
      await _templateField(
        db,
        't1',
        'secret_note',
        1,
        validation: '{"_tapture":{"hidden":true}}',
      );
      await _templateField(db, 't1', 'district', 2, contextLevel: 1);
      await _templateField(db, 't1', 'asset_tag', 3);
      await _templateField(db, 't1', 'nameplate', 4, type: 'photo_reference');
      await _templateField(db, 't1', 'site_name', 5);
      await _templateField(db, 't1', 'equipment_name', 6);
      await _templateField(db, 't1', 'serial_number', 7);
      await _templateField(
        db,
        't1',
        'room',
        8,
        validation: '{"_tapture":{"identity":true}}',
      );
      await seedRow(db, 'template_rows', <String, Object?>{
        'id': 'row-1',
        'template_id': 't1',
        'output_row_number': 4,
        'identifier': 'CHK-004',
        'label': 'Main switchboard',
      });
    });

    test(
      'the name is the first visible field that is not an identity field',
      () async {
        await seedRecord(db, 'r1');
        await seedField(
          db,
          'f1',
          recordId: 'r1',
          fieldKey: 'record_uid',
          raw: 'U-1',
        );
        await seedField(
          db,
          'f2',
          recordId: 'r1',
          fieldKey: 'secret_note',
          raw: 'Hidden',
        );
        await seedField(
          db,
          'f3',
          recordId: 'r1',
          fieldKey: 'district',
          raw: 'North',
        );
        await seedField(
          db,
          'f4',
          recordId: 'r1',
          fieldKey: 'asset_tag',
          raw: 'AT-9',
        );
        await seedField(
          db,
          'f5',
          recordId: 'r1',
          fieldKey: 'nameplate',
          raw: 'ph1',
        );
        await seedField(
          db,
          'f6',
          recordId: 'r1',
          fieldKey: 'site_name',
          raw: 'Depot',
          source: 'CONTEXT',
        );
        await seedField(
          db,
          'f7',
          recordId: 'r1',
          fieldKey: 'equipment_name',
          raw: 'pump',
          refined: 'Booster pump',
        );
        await seedField(
          db,
          'f8',
          recordId: 'r1',
          fieldKey: 'serial_number',
          raw: 'SN-77',
        );
        await seedField(db, 'f9', recordId: 'r1', fieldKey: 'room', raw: 'B12');

        final ({String projectId, String name, String identifier})? doc =
            await searchDoc(db, 'r1');
        expect(doc?.name, 'Booster pump');
        expect(doc?.identifier, 'SN-77 AT-9 B12');
      },
    );

    test(
      'a retired or tombstoned value is neither the name nor the identifier',
      () async {
        final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 17, 8));
        await seedRecord(db, 'r1');
        await seedField(
          db,
          'f1',
          recordId: 'r1',
          fieldKey: 'equipment_name',
          raw: 'Booster pump',
        );
        await seedField(
          db,
          'f2',
          recordId: 'r1',
          fieldKey: 'serial_number',
          raw: 'SN-77',
        );
        await db.transaction(() async {
          await setRecordFieldRetired(db, id: 'f1', clock: clock);
        });
        await writeTombstone(
          db,
          entityType: 'record_fields',
          entityId: 'f2',
          reason: 'removed',
        );
        final ({String projectId, String name, String identifier})? doc =
            await searchDoc(db, 'r1');
        expect(doc?.name, '');
        expect(doc?.identifier, '');
        expect(await searchRecords(db, 'booster'), <String>['r1']);
      },
    );

    test(
      'without a name value the latest record caption names the record',
      () async {
        await seedRecord(db, 'r1');
        await seedCaption(
          db,
          'c1',
          ownerType: 'record',
          ownerId: 'r1',
          text: 'Old caption',
        );
        await seedCaption(
          db,
          'c2',
          ownerType: 'record',
          ownerId: 'r1',
          text: 'Leaking tap\nin the yard',
          createdAt: 5,
        );
        expect((await searchDoc(db, 'r1'))?.name, 'Leaking tap in the yard');
      },
    );

    test(
      'without identity values the checklist row identifies the record',
      () async {
        await seedRecord(db, 'r1', templateRowId: 'row-1');
        expect((await searchDoc(db, 'r1'))?.identifier, 'CHK-004');
        expect(await searchRecords(db, 'switchboard'), <String>['r1']);
      },
    );

    test('malformed template JSON does not stop a write', () async {
      await db.customStatement(
        "UPDATE templates SET identity_fields = 'not json' WHERE id = 't1'",
      );
      await db.customStatement(
        "UPDATE template_fields SET validation = '{broken' "
        "WHERE field_key = 'equipment_name'",
      );
      await seedRecord(db, 'r1');
      await seedField(
        db,
        'f1',
        recordId: 'r1',
        fieldKey: 'equipment_name',
        raw: 'Booster pump',
      );
      expect((await searchDoc(db, 'r1'))?.name, 'Booster pump');
    });

    test('sorting a project by name reads the docs index in order', () async {
      final List<QueryRow> plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT record_id FROM record_search_docs '
            "WHERE project_id = 'p1' ORDER BY sort_name, record_id LIMIT 50",
          )
          .get();
      final String details = plan
          .map((QueryRow row) => row.read<String>('detail'))
          .join('; ');
      expect(details, contains(RecordSchema.searchDocsByName));
      expect(details, isNot(contains('TEMP B-TREE')));
    });
  });

  test('every index and trigger the schema names exists', () async {
    final List<QueryRow> rows = await db
        .customSelect(
          "SELECT type, name FROM sqlite_master WHERE type IN "
          "('index', 'trigger', 'view', 'table')",
        )
        .get();
    final Set<String> names = <String>{
      for (final QueryRow row in rows) row.read<String>('name'),
    };
    expect(names, containsAll(RecordSchema.indexNames));
    expect(names, containsAll(RecordSchema.triggerNames));
    expect(
      names,
      containsAll(<String>[
        RecordSchema.searchDocsTable,
        RecordSchema.searchTable,
        RecordSchema.searchSourceView,
      ]),
    );
  });

  test('ensure runs twice and leaves the same rows and schema', () async {
    await seedRecord(db, 'r1', status: 'CAPTURED');
    await seedField(db, 'f1', recordId: 'r1', fieldKey: 'model', raw: 'Wilo');
    final List<QueryRow> before = await db
        .customSelect('SELECT type, name, sql FROM sqlite_master ORDER BY name')
        .get();

    await RecordSchema.ensure(db);
    await RecordSchema.ensure(db);

    final List<QueryRow> after = await db
        .customSelect('SELECT type, name, sql FROM sqlite_master ORDER BY name')
        .get();
    expect(
      after.map((QueryRow row) => row.data.toString()).toList(),
      before.map((QueryRow row) => row.data.toString()).toList(),
    );
    expect(await searchRecords(db, 'wilo'), <String>['r1']);
    expect(await numberOf(db, 'r1'), 1);
    final QueryRow docs = await db
        .customSelect('SELECT COUNT(*) AS n FROM record_search')
        .getSingle();
    expect(docs.read<int>('n'), 1);
  });

  group('deferred indexing', () {
    test(
      'bulk writes are indexed once, before the transaction that made them ends',
      () async {
        final int written = await RecordSchema.deferIndexing(db, () async {
          for (int i = 0; i < 3; i++) {
            await seedRecord(db, 'r$i', status: 'CAPTURED');
            await seedField(
              db,
              'f$i',
              recordId: 'r$i',
              fieldKey: 'model',
              raw: 'Grundfos $i',
            );
          }
          expect(await searchRecords(db, 'grundfos'), isEmpty);
          return 3;
        });

        expect(written, 3);
        expect(await searchRecords(db, 'grundfos'), <String>['r0', 'r1', 'r2']);
        expect(await statusOf(db, 'r1'), 'captured');
        expect(await numberOf(db, 'r2'), 3);
        expect(await _count(db, RecordSchema.searchHoldTable), 0);
        expect(await _count(db, RecordSchema.searchPendingTable), 0);
        expect(await _count(db, RecordSchema.searchTable), 3);

        await seedField(db, 'g1', recordId: 'r0', fieldKey: 'k', raw: 'Wilo');
        expect(await searchRecords(db, 'wilo'), <String>['r0']);
      },
    );

    test('a nested call leaves the rebuild to the outer one', () async {
      await RecordSchema.deferIndexing(db, () async {
        await seedRecord(db, 'r1');
        await RecordSchema.deferIndexing(db, () async {
          await seedField(
            db,
            'f1',
            recordId: 'r1',
            fieldKey: 'k',
            raw: 'Xylem',
          );
        });
        expect(await _count(db, RecordSchema.searchHoldTable), 1);
        expect(await searchRecords(db, 'xylem'), isEmpty);
      });
      expect(await searchRecords(db, 'xylem'), <String>['r1']);
    });

    test('a failed bulk write rolls back with its hold', () async {
      await seedRecord(db, 'r1');
      await expectLater(
        RecordSchema.deferIndexing(db, () async {
          await seedField(
            db,
            'f1',
            recordId: 'r1',
            fieldKey: 'k',
            raw: 'Xylem',
          );
          throw const StorageFailure(message: 'fail');
        }),
        throwsA(isA<StorageFailure>()),
      );
      expect(await _count(db, RecordSchema.searchHoldTable), 0);
      expect(await _count(db, RecordSchema.searchPendingTable), 0);
      await seedField(db, 'f2', recordId: 'r1', fieldKey: 'k', raw: 'Wilo');
      expect(await searchRecords(db, 'wilo'), <String>['r1']);
      expect(await searchRecords(db, 'xylem'), isEmpty);
    });
  });

  test('a failed write rolls its search document back with it', () async {
    await seedRecord(db, 'r1');
    await expectLater(
      db.transaction(() async {
        await seedField(
          db,
          'f1',
          recordId: 'r1',
          fieldKey: 'model',
          raw: 'Grundfos',
        );
        throw const StorageFailure(message: 'fail');
      }),
      throwsA(isA<StorageFailure>()),
    );
    expect(await searchRecords(db, 'grundfos'), isEmpty);
  });
}

Future<int> _count(AppDatabase db, String table) async {
  final QueryRow row = await db
      .customSelect('SELECT COUNT(*) AS n FROM $table')
      .getSingle();
  return row.read<int>('n');
}

Future<void> _templateField(
  AppDatabase db,
  String templateId,
  String fieldKey,
  int sortOrder, {
  String type = 'text',
  String inputMode = '',
  int? contextLevel,
  String validation = '{}',
}) {
  return seedRow(db, 'template_fields', <String, Object?>{
    'id': '$templateId-$fieldKey',
    'template_id': templateId,
    'field_key': fieldKey,
    'label': fieldKey,
    'type': type,
    'input_mode': inputMode,
    'context_level': contextLevel,
    'validation': validation,
    'sort_order': sortOrder,
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
