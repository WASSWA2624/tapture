import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../record_rows.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;
  late String recordId;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  setUp(() async {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
    recordId = _ok(
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
          capturedBy: const Value<String>('Ada'),
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
    'refinement leaves valueRaw byte-identical and a second raw write is refused',
    () async {
      const String raw = 'SN-001';
      final RecordField created = _ok(
        await insertRecordField(
          db,
          row: RecordFieldsCompanion(
            recordId: Value<String>(recordId),
            fieldKey: const Value<String>('serial'),
            valueRaw: const Value<String>(raw),
            source: const Value<String>('typed'),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(created.valueRaw, raw);

      final RecordField refined = _ok(
        await writeRecordFieldRefined(
          db,
          id: created.id,
          valueRefined: 'SN-001-clean',
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(refined.valueRaw, raw);
      expect(refined.valueRefined, 'SN-001-clean');

      final Result<RecordField> secondRaw = await insertRecordField(
        db,
        row: RecordFieldsCompanion(
          id: Value<String>(created.id),
          valueRaw: const Value<String>('changed'),
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      );
      expect(
        secondRaw.fold((Failure failure) => failure, (_) => null),
        isA<StorageFailure>(),
      );
      final RecordField stored =
          await (db.select(db.recordFields)
                ..where(($RecordFieldsTable tbl) => tbl.id.equals(created.id)))
              .getSingle();
      expect(stored.valueRaw, raw);
    },
  );

  test(
    'a duplicate fieldKey for one record is refused by the unique index',
    () async {
      _ok(
        await insertRecordField(
          db,
          row: RecordFieldsCompanion(
            recordId: Value<String>(recordId),
            fieldKey: const Value<String>('serial'),
            valueRaw: const Value<String>('a'),
            source: const Value<String>('typed'),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final Result<RecordField> duplicate = await insertRecordField(
        db,
        row: RecordFieldsCompanion(
          recordId: Value<String>(recordId),
          fieldKey: const Value<String>('serial'),
          valueRaw: const Value<String>('b'),
          source: const Value<String>('typed'),
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      );
      late StorageFailure failure;
      duplicate.fold((Failure value) {
        failure = value as StorageFailure;
      }, (_) => fail('expected a uniqueness failure'));
      expect(failure.message, contains('already exists'));
      expect(failure.recoveryAction, isNotEmpty);
    },
  );

  test(
    'version 5 creates the record_fields table with merge columns',
    () async {
      await db.close();
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_record_fields_',
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
        await _columns(upgraded, 'record_fields'),
        containsAll(<String>[
          'id',
          'created_at',
          'updated_at',
          'updated_by_device',
          'rev',
          'record_id',
          'field_key',
          'value_raw',
          'value_refined',
          'value_final',
          'confidence',
          'source',
          'verified',
          'verified_by',
          'verified_at',
          'evidence_removed_at',
          'retired_at',
        ]),
      );
    },
  );

  group('value flags', () {
    final DateTime t1 = t0.add(const Duration(minutes: 5));

    test(
      'evidence removed is set and cleared with a revision bump and one audit row each',
      () async {
        await seedField(
          db,
          'f1',
          recordId: recordId,
          fieldKey: 'serial',
          raw: 'SN-1',
        );

        expect(
          await setRecordFieldEvidenceRemoved(
            db,
            id: 'f1',
            clock: FixedClock(t1),
            deviceId: 'device-b',
            operator: 'Ada',
          ),
          isTrue,
        );
        RecordField stored = await _field(db, 'f1');
        expect(stored.evidenceRemovedAt?.toUtc(), t1);
        expect(stored.rev, 2);
        expect(stored.updatedByDevice, 'device-b');
        expect(stored.valueRaw, 'SN-1');

        expect(
          await setRecordFieldEvidenceRemoved(db, id: 'f1'),
          isFalse,
          reason: 'already flagged',
        );
        expect(
          await clearRecordFieldEvidenceRemoved(
            db,
            id: 'f1',
            clock: FixedClock(t1),
          ),
          isTrue,
        );
        stored = await _field(db, 'f1');
        expect(stored.evidenceRemovedAt, isNull);
        expect(stored.rev, 3);

        final List<AuditLogData> audit = await _flagAudit(db);
        expect(audit, hasLength(2));
        expect(audit.first.entityType, 'records');
        expect(audit.first.entityId, recordId);
        expect(audit.first.action, AuditAction.updated);
        expect(audit.first.fieldKey, 'serial');
        expect(audit.first.reason, evidenceRemovedAuditReason);
        expect(audit.first.previousValue, 'false');
        expect(audit.first.newValue, 'true');
        expect(audit.first.operator, 'Ada');
        expect(audit.last.previousValue, 'true');
        expect(audit.last.newValue, 'false');
      },
    );

    test(
      'a retired value is kept, audited, and comes back when cleared',
      () async {
        await seedField(
          db,
          'f1',
          recordId: recordId,
          fieldKey: 'colour',
          raw: 'Red',
          refined: 'Crimson',
        );

        expect(
          await setRecordFieldRetired(db, id: 'f1', clock: FixedClock(t1)),
          isTrue,
        );
        RecordField stored = await _field(db, 'f1');
        expect(stored.retiredAt?.toUtc(), t1);
        expect(stored.valueRaw, 'Red');
        expect(stored.valueRefined, 'Crimson');

        expect(await setRecordFieldRetired(db, id: 'f1'), isFalse);
        expect(await clearRecordFieldRetired(db, id: 'f1'), isTrue);
        expect(await clearRecordFieldRetired(db, id: 'f1'), isFalse);
        stored = await _field(db, 'f1');
        expect(stored.retiredAt, isNull);

        final List<AuditLogData> audit = await _flagAudit(db);
        expect(audit.map((AuditLogData row) => row.reason), <String>[
          retiredAuditReason,
          retiredAuditReason,
        ]);
        expect(audit.map((AuditLogData row) => row.fieldKey).toSet(), <String>{
          'colour',
        });
      },
    );

    test('a flag on a value that is not on this device fails', () async {
      await expectLater(
        setRecordFieldRetired(db, id: 'missing'),
        throwsA(isA<StorageFailure>()),
      );
      expect(await _flagAudit(db), isEmpty);
    });

    test(
      'a removed photo flags only values with no live photo evidence left, and its restore clears them',
      () async {
        await seedPhoto(db, 'ph1', recordId: recordId);
        await seedPhoto(db, 'ph2', recordId: recordId);
        await seedField(
          db,
          'f1',
          recordId: recordId,
          fieldKey: 'serial',
          raw: 'SN-1',
        );
        await seedField(
          db,
          'f2',
          recordId: recordId,
          fieldKey: 'model',
          raw: 'CR-45',
          source: 'extraction',
        );
        await seedField(
          db,
          'f3',
          recordId: recordId,
          fieldKey: 'site',
          raw: 'Depot',
          source: 'TYPED',
        );
        await seedField(
          db,
          'f4',
          recordId: recordId,
          fieldKey: 'notes',
          raw: 'ok',
        );
        await seedEvidence(db, 'e1', fieldId: 'f1', photoId: 'ph1');
        await seedEvidence(db, 'e2', fieldId: 'f2', photoId: 'ph1');
        await seedEvidence(db, 'e3', fieldId: 'f2', photoId: 'ph2');
        await seedEvidence(db, 'e4', fieldId: 'f3', photoId: 'ph1');

        final List<String> first = await db.transaction(() async {
          await writeTombstone(
            db,
            entityType: 'photos',
            entityId: 'ph1',
            reason: 'removed',
            clock: FixedClock(t1),
          );
          return flagEvidenceRemovedForPhoto(
            db,
            photoId: 'ph1',
            clock: FixedClock(t1),
            operator: 'Ada',
          );
        });
        expect(first, <String>['serial']);
        expect((await _field(db, 'f1')).evidenceRemovedAt?.toUtc(), t1);
        expect((await _field(db, 'f2')).evidenceRemovedAt, isNull);
        expect((await _field(db, 'f3')).evidenceRemovedAt, isNull);
        expect((await _field(db, 'f4')).evidenceRemovedAt, isNull);
        expect((await _field(db, 'f1')).valueRaw, 'SN-1');

        await writeTombstone(
          db,
          entityType: 'photos',
          entityId: 'ph2',
          reason: 'removed',
        );
        expect(await flagEvidenceRemovedForPhoto(db, photoId: 'ph2'), <String>[
          'model',
        ]);
        expect(
          await flagEvidenceRemovedForPhoto(db, photoId: 'ph2'),
          isEmpty,
          reason: 'already flagged',
        );

        await removeTombstone(db, entityType: 'photos', entityId: 'ph1');
        expect(await clearEvidenceRemovedForPhoto(db, photoId: 'ph1'), <String>[
          'model',
          'serial',
        ]);
        expect((await _field(db, 'f1')).evidenceRemovedAt, isNull);
        expect((await _field(db, 'f2')).evidenceRemovedAt, isNull);
        expect(
          (await _flagAudit(db)).map((AuditLogData row) => row.fieldKey),
          <String>['serial', 'model', 'model', 'serial'],
        );
      },
    );

    test(
      'evidence on one photo of an edit chain stays live while another copy is live',
      () async {
        await seedPhoto(db, 'original', recordId: recordId);
        await seedPhoto(
          db,
          'rotated',
          recordId: recordId,
          derivedFrom: 'original',
        );
        await seedField(
          db,
          'f1',
          recordId: recordId,
          fieldKey: 'serial',
          raw: 'SN-1',
        );
        await seedField(
          db,
          'f2',
          recordId: recordId,
          fieldKey: 'model',
          raw: 'CR',
        );
        await seedEvidence(db, 'e1', fieldId: 'f1', photoId: 'rotated');
        await seedEvidence(db, 'e2', fieldId: 'f2', photoId: 'original');

        await writeTombstone(
          db,
          entityType: 'photos',
          entityId: 'rotated',
          reason: 'Reverted to the original photo.',
        );
        expect(
          await flagEvidenceRemovedForPhoto(db, photoId: 'rotated'),
          isEmpty,
        );

        await writeTombstone(
          db,
          entityType: 'photos',
          entityId: 'original',
          reason: 'removed',
        );
        expect(
          await flagEvidenceRemovedForPhoto(db, photoId: 'original'),
          <String>['model', 'serial'],
        );
      },
    );

    test('an unfiled or unknown photo flags nothing', () async {
      await seedPhoto(db, 'loose', recordId: null);
      expect(await flagEvidenceRemovedForPhoto(db, photoId: 'loose'), isEmpty);
      expect(await flagEvidenceRemovedForPhoto(db, photoId: 'ghost'), isEmpty);
      expect(await clearEvidenceRemovedForPhoto(db, photoId: 'ghost'), isEmpty);
    });

    test('flags roll back with the transaction that wrote them', () async {
      await seedPhoto(db, 'ph1', recordId: recordId);
      await seedField(
        db,
        'f1',
        recordId: recordId,
        fieldKey: 'serial',
        raw: 'SN-1',
      );
      await seedEvidence(db, 'e1', fieldId: 'f1', photoId: 'ph1');

      final Result<void> result = await runInTransaction(db, () async {
        await writeTombstone(
          db,
          entityType: 'photos',
          entityId: 'ph1',
          reason: 'removed',
        );
        await flagEvidenceRemovedForPhoto(db, photoId: 'ph1');
        throw const StorageFailure(message: 'fail');
      });

      expect(result, isA<FailureResult<void>>());
      expect((await _field(db, 'f1')).evidenceRemovedAt, isNull);
      expect(await _flagAudit(db), isEmpty);
    });
  });

  group('operator edits', () {
    final DateTime t1 = t0.add(const Duration(minutes: 5));

    test(
      'an edit writes the refined value, supersedes the approved one and audits what showed',
      () async {
        await seedField(
          db,
          'f1',
          recordId: recordId,
          fieldKey: 'colour',
          raw: 'Red',
          refined: 'Crimson',
          approved: 'Scarlet',
        );

        expect(
          await writeRecordFieldEdit(
            db,
            id: 'f1',
            value: 'Maroon',
            clock: FixedClock(t1),
            deviceId: 'device-b',
            operator: 'Ada',
            reason: 'Checked on site',
          ),
          isTrue,
        );

        final RecordField stored = await _field(db, 'f1');
        expect(stored.valueRaw, 'Red');
        expect(stored.valueRefined, 'Maroon');
        expect(stored.valueFinal, isNull);
        expect(stored.source, recordFieldEditSource);
        expect(stored.verified, isTrue);
        expect(stored.verifiedBy, 'Ada');
        expect(stored.verifiedAt?.toUtc(), t1);
        expect(stored.rev, 2);
        expect(stored.updatedAt.toUtc(), t1);
        expect(stored.updatedByDevice, 'device-b');

        final AuditLogData audit = (await _allAudit(db)).single;
        expect(audit.entityType, 'records');
        expect(audit.entityId, recordId);
        expect(audit.action, AuditAction.updated);
        expect(audit.fieldKey, 'colour');
        expect(audit.previousValue, 'Scarlet');
        expect(audit.newValue, 'Maroon');
        expect(audit.reason, 'Checked on site');
        expect(audit.operator, 'Ada');
        expect(audit.device, 'device-b');
        expect(audit.at.toUtc(), t1);
      },
    );

    test(
      'the previous value is what showed: refined over raw, raw alone, or nothing',
      () async {
        await seedField(
          db,
          'refined',
          recordId: recordId,
          fieldKey: 'a',
          raw: 'Red',
          refined: 'Crimson',
        );
        await seedField(db, 'raw', recordId: recordId, fieldKey: 'b', raw: 'X');
        await seedField(
          db,
          'blank-final',
          recordId: recordId,
          fieldKey: 'c',
          raw: 'Y',
          approved: '',
        );
        await seedField(db, 'empty', recordId: recordId, fieldKey: 'd');

        for (final String id in <String>[
          'refined',
          'raw',
          'blank-final',
          'empty',
        ]) {
          expect(await writeRecordFieldEdit(db, id: id, value: 'New'), isTrue);
        }

        expect(
          (await _allAudit(db)).map((AuditLogData row) => row.previousValue),
          <String?>['Crimson', 'X', 'Y', null],
        );
      },
    );

    test('an edit to what already shows writes nothing', () async {
      await seedField(
        db,
        'f1',
        recordId: recordId,
        fieldKey: 'colour',
        raw: 'Red',
        refined: 'Crimson',
      );

      expect(
        await writeRecordFieldEdit(db, id: 'f1', value: 'Crimson'),
        isFalse,
      );

      final RecordField stored = await _field(db, 'f1');
      expect(stored.rev, 1);
      expect(stored.source, 'ocr');
      expect(stored.verified, isFalse);
      expect(await _allAudit(db), isEmpty);
    });

    test(
      'a removed value comes back with the edit and no previous value',
      () async {
        await seedField(
          db,
          'f1',
          recordId: recordId,
          fieldKey: 'colour',
          raw: 'Red',
        );
        await writeTombstone(
          db,
          entityType: 'record_fields',
          entityId: 'f1',
          reason: 'Removed on another device.',
        );

        expect(await writeRecordFieldEdit(db, id: 'f1', value: ''), isFalse);
        expect(await _tombstoned(db, 'f1'), isTrue);

        expect(await writeRecordFieldEdit(db, id: 'f1', value: 'Red'), isTrue);
        expect(await _tombstoned(db, 'f1'), isFalse);
        expect((await _field(db, 'f1')).valueRefined, 'Red');
        final AuditLogData audit = (await _allAudit(db)).single;
        expect(audit.previousValue, isNull);
        expect(audit.newValue, 'Red');
      },
    );

    test('an edit leaves the value flags alone', () async {
      await seedField(
        db,
        'f1',
        recordId: recordId,
        fieldKey: 'colour',
        raw: 'Red',
      );
      await setRecordFieldRetired(db, id: 'f1', clock: FixedClock(t0));
      await setRecordFieldEvidenceRemoved(db, id: 'f1', clock: FixedClock(t0));

      expect(await writeRecordFieldEdit(db, id: 'f1', value: 'Blue'), isTrue);

      final RecordField stored = await _field(db, 'f1');
      expect(stored.retiredAt?.toUtc(), t0);
      expect(stored.evidenceRemovedAt?.toUtc(), t0);
    });

    test('an edit of a value not on this device fails', () async {
      await expectLater(
        writeRecordFieldEdit(db, id: 'missing', value: 'x'),
        throwsA(isA<StorageFailure>()),
      );
      expect(await _allAudit(db), isEmpty);
    });

    test('an edit rolls back with the transaction that wrote it', () async {
      await seedField(
        db,
        'f1',
        recordId: recordId,
        fieldKey: 'colour',
        raw: 'Red',
      );

      final Result<void> result = await runInTransaction(db, () async {
        await writeRecordFieldEdit(db, id: 'f1', value: 'Blue');
        throw const StorageFailure(message: 'fail');
      });

      expect(result, isA<FailureResult<void>>());
      final RecordField stored = await _field(db, 'f1');
      expect(stored.valueRefined, isNull);
      expect(stored.rev, 1);
      expect(await _allAudit(db), isEmpty);
    });
  });
}

/// Every audit row, in write order.
Future<List<AuditLogData>> _allAudit(AppDatabase db) async {
  final List<QueryRow> rows = await db
      .customSelect('SELECT * FROM audit_log ORDER BY rowid')
      .get();
  return <AuditLogData>[
    for (final QueryRow row in rows) db.auditLog.map(row.data),
  ];
}

/// Whether value [id] carries a tombstone.
Future<bool> _tombstoned(AppDatabase db, String id) async {
  final QueryRow? row = await db
      .customSelect(
        "SELECT 1 FROM tombstones WHERE entity_type = 'record_fields' "
        'AND entity_id = ?',
        variables: <Variable<Object>>[Variable<String>(id)],
      )
      .getSingleOrNull();
  return row != null;
}

Future<RecordField> _field(AppDatabase db, String id) {
  return (db.select(
    db.recordFields,
  )..where(($RecordFieldsTable tbl) => tbl.id.equals(id))).getSingle();
}

/// Audit rows written by the flag helpers, in write order.
Future<List<AuditLogData>> _flagAudit(AppDatabase db) async {
  final List<QueryRow> rows = await db
      .customSelect(
        'SELECT * FROM audit_log WHERE reason IN (?, ?) ORDER BY rowid',
        variables: <Variable<Object>>[
          const Variable<String>(evidenceRemovedAuditReason),
          const Variable<String>(retiredAuditReason),
        ],
      )
      .get();
  return <AuditLogData>[
    for (final QueryRow row in rows) db.auditLog.map(row.data),
  ];
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
