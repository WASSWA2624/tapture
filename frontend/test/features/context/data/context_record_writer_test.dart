import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_path_builder.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/context/data/context_record_writer.dart';
import 'package:tapture/features/context/data/context_repository_impl.dart';
import 'package:tapture/features/context/domain/context_application.dart';
import 'package:tapture/features/context/domain/context_folder_link.dart';
import 'package:tapture/features/context/domain/context_state.dart';

void main() {
  late AppDatabase db;
  late ContextRepositoryImpl repo;
  late ContextRecordWriter writer;
  final DateTime t0 = DateTime.utc(2026, 9, 22, 8);
  late UuidV7Service ids;

  const ContextState three = ContextState(
    levels: <ContextLevel>[
      ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
      ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
      ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
    ],
    values: <String, String>{
      'district': 'Kampala',
      'facility': 'Kasubi HC IV',
      'dept': 'Theatre',
    },
    pinned: <String, String>{'surveyor': 'Sam'},
  );

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
    repo = ContextRepositoryImpl(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    writer = ContextRecordWriter(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
      operator: 'Ada',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'a new record stores CONTEXT values and leaves siblings alone',
    () async {
      _ok(await repo.saveHierarchy('proj-1', three.levels));
      for (final MapEntry<String, String> entry in three.values.entries) {
        _ok(
          await repo.setLevelValue(
            projectId: 'proj-1',
            fieldKey: entry.key,
            value: entry.value,
          ),
        );
      }
      _ok(await repo.savePinned('proj-1', three.pinned));
      final ContextState live = _ok(await repo.load('proj-1'));
      final RecordRow first = _ok(
        await upsertRecord(
          db,
          row: _record('h-1'),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final RecordRow second = _ok(
        await upsertRecord(
          db,
          row: _record('h-2'),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(await writer.applyToRecord(recordId: first.id, state: live));
      _ok(await writer.applyToRecord(recordId: second.id, state: live));

      final List<RecordField> firstFields = await _fields(db, first.id);
      expect(
        firstFields.map((RecordField field) => field.source),
        everyElement(ContextApplication.source),
      );
      expect(_raw(firstFields, 'dept'), 'Theatre');
      expect(_raw(firstFields, 'surveyor'), 'Sam');

      _ok(
        await writer.overrideField(
          recordId: first.id,
          fieldKey: 'dept',
          newValue: 'Laboratory',
        ),
      );
      final List<RecordField> edited = await _fields(db, first.id);
      final RecordField dept = edited.singleWhere(
        (RecordField field) => field.fieldKey == 'dept',
      );
      expect(dept.valueRaw, 'Theatre');
      expect(dept.valueRefined, 'Laboratory');
      expect(dept.source, ContextApplication.source);
      final List<AuditLogData> audits = await (db.select(
        db.auditLog,
      )..where(($AuditLogTable tbl) => tbl.entityId.equals(first.id))).get();
      expect(
        audits.any(
          (AuditLogData row) =>
              row.action == AuditAction.updated &&
              row.fieldKey == 'dept' &&
              row.newValue == 'Laboratory',
        ),
        isTrue,
      );

      final List<RecordField> sibling = await _fields(db, second.id);
      expect(_raw(sibling, 'dept'), 'Theatre');
      expect(
        sibling
            .singleWhere((RecordField field) => field.fieldKey == 'dept')
            .valueRefined,
        isNull,
      );
      final ContextState after = _ok(await repo.load('proj-1'));
      expect(after.values['dept'], 'Theatre');
      expect(after.values['facility'], 'Kasubi HC IV');
    },
  );

  test(
    'capturing into a three-level context writes the specification folder',
    () async {
      final RecordRow row = _ok(
        await upsertRecord(
          db,
          row: _record('h-path'),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(await writer.applyToRecord(recordId: row.id, state: three));
      final RecordRow stored = await (db.select(
        db.records,
      )..where(($RecordsTable tbl) => tbl.id.equals(row.id))).getSingle();
      final Map<String, Object?> snapshot = _objectMap(
        jsonDecode(stored.contextJson),
      );
      expect(
        ContextFolderLink.photoFolder(
          strategy: PhotoFolderStrategy.byContext,
          snapshot: snapshot,
        ),
        'photos/Kampala/Kasubi-HC-IV/Theatre',
      );
      _ok(
        await repo.saveHierarchy('proj-1', const <ContextLevel>[
          ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
        ]),
      );
      _ok(
        await repo.setLevelValue(
          projectId: 'proj-1',
          fieldKey: 'district',
          value: 'Wakiso',
        ),
      );
      final RecordRow unchanged = await (db.select(
        db.records,
      )..where(($RecordsTable tbl) => tbl.id.equals(row.id))).getSingle();
      expect(unchanged.contextJson, stored.contextJson);
    },
  );
}

RecordsCompanion _record(String identityHash) {
  return RecordsCompanion(
    projectId: const Value<String>('proj-1'),
    templateId: const Value<String>('t1'),
    status: const Value<String>('captured'),
    processingMode: const Value<String>('manual'),
    contextJson: const Value<String>('{}'),
    identityHash: Value<String>(identityHash),
    source: const Value<String>('capture'),
    capturedAt: Value<DateTime>(DateTime.utc(2026, 9, 22, 8)),
    capturedBy: const Value<String>('Ada'),
  );
}

Future<List<RecordField>> _fields(AppDatabase db, String recordId) {
  return (db.select(
    db.recordFields,
  )..where(($RecordFieldsTable tbl) => tbl.recordId.equals(recordId))).get();
}

String? _raw(List<RecordField> fields, String key) {
  for (final RecordField field in fields) {
    if (field.fieldKey == key) {
      return field.valueRaw;
    }
  }
  return null;
}

Map<String, Object?> _objectMap(Object? raw) {
  final Map<String, Object?> out = <String, Object?>{};
  if (raw is Map) {
    for (final MapEntry<Object?, Object?> entry in raw.entries) {
      final Object? key = entry.key;
      if (key != null) {
        out['$key'] = entry.value;
      }
    }
  }
  return out;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
