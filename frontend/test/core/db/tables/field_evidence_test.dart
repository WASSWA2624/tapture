import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/field_evidence.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;
  late String fieldId;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  setUp(() async {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
    final RecordRow record = _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          projectId: const Value<String>('p1'),
          templateId: const Value<String>('t1'),
          status: const Value<String>('captured'),
          processingMode: const Value<String>('online'),
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
    );
    fieldId = _ok(
      await insertRecordField(
        db,
        row: RecordFieldsCompanion(
          recordId: Value<String>(record.id),
          fieldKey: const Value<String>('serial'),
          valueRaw: const Value<String>('SN-001'),
          source: const Value<String>('extraction'),
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
    'photo, document and transcript evidence resolve, and deleting the field leaves a tombstone',
    () async {
      final FieldEvidenceRow photo = _ok(
        await insertFieldEvidence(
          db,
          row: FieldEvidenceCompanion(
            recordFieldId: Value<String>(fieldId),
            sourceType: const Value<FieldEvidenceSource>(
              FieldEvidenceSource.photo,
            ),
            photoId: const Value<String>('photo-1'),
            region: Value<String>(
              jsonEncode(<String, int>{'x': 1, 'y': 2, 'w': 3, 'h': 4}),
            ),
            confidence: const Value<double>(0.9),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final FieldEvidenceRow document = _ok(
        await insertFieldEvidence(
          db,
          row: FieldEvidenceCompanion(
            recordFieldId: Value<String>(fieldId),
            sourceType: const Value<FieldEvidenceSource>(
              FieldEvidenceSource.document,
            ),
            documentId: const Value<String>('doc-1'),
            page: const Value<int>(3),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final FieldEvidenceRow transcript = _ok(
        await insertFieldEvidence(
          db,
          row: FieldEvidenceCompanion(
            recordFieldId: Value<String>(fieldId),
            sourceType: const Value<FieldEvidenceSource>(
              FieldEvidenceSource.transcript,
            ),
            snippet: const Value<String>('serial SN-001'),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final List<FieldEvidenceRow> rows = _ok(
        await listFieldEvidenceForField(db, recordFieldId: fieldId),
      );
      expect(rows, hasLength(3));
      expect(photo.photoId, 'photo-1');
      expect(jsonDecode(photo.region!), <String, int>{
        'x': 1,
        'y': 2,
        'w': 3,
        'h': 4,
      });
      expect(document.documentId, 'doc-1');
      expect(document.page, 3);
      expect(transcript.snippet, 'serial SN-001');
      expect(
        rows.map((FieldEvidenceRow row) => row.sourceType).toSet(),
        <FieldEvidenceSource>{
          FieldEvidenceSource.photo,
          FieldEvidenceSource.document,
          FieldEvidenceSource.transcript,
        },
      );

      _ok(
        await softDeleteRecordField(
          db,
          id: fieldId,
          reason: 'remove field',
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      expect(
        await (db.select(db.recordFields)
              ..where(($RecordFieldsTable tbl) => tbl.id.equals(fieldId)))
            .getSingleOrNull(),
        isNotNull,
      );
      expect(
        _ok(await listFieldEvidenceForField(db, recordFieldId: fieldId)),
        hasLength(3),
      );
      final List<Tombstone> marks =
          await (db.select(db.tombstones)..where(
                ($TombstonesTable tbl) =>
                    tbl.entityType.equals('record_fields') &
                    tbl.entityId.equals(fieldId),
              ))
              .get();
      expect(marks, hasLength(1));
      expect(marks.single.reason, 'remove field');
    },
  );

  test(
    'version 8 creates the field_evidence table with merge columns',
    () async {
      await db.close();
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_field_evidence_',
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
        await _columns(upgraded, 'field_evidence'),
        containsAll(<String>[
          'id',
          'created_at',
          'updated_at',
          'updated_by_device',
          'rev',
          'record_field_id',
          'source_type',
          'photo_id',
          'document_id',
          'page',
          'region',
          'snippet',
          'confidence',
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
