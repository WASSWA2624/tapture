import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';
import 'package:tapture/features/templates/presentation/field_delete_action.dart';

import '../../../support/factories.dart';

void main() {
  const FieldDef serial = FieldDef(
    fieldKey: 'serial',
    label: 'Serial',
    type: FieldType.text,
    outputColumn: 'B',
  );
  const FieldDef name = FieldDef(
    fieldKey: 'asset_name',
    label: 'Name',
    type: FieldType.text,
    outputColumn: 'C',
  );

  test('retire drops the field and leaves other output columns', () {
    final TemplateDef next = FieldDeleteAction.retire(
      aTemplate(
        fields: const <FieldDef>[serial, name],
        identityFieldKeys: const <String>['serial', 'asset_name'],
      ),
      'serial',
    );
    expect(next.fields, const <FieldDef>[name]);
    expect(next.identityFieldKeys, const <String>['asset_name']);
    expect(next.fields.single.outputColumn, 'C');
  });

  test('retired values survive a delete and export as retired', () async {
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final DateTime t0 = DateTime.utc(2026, 9, 20, 8);
    final FixedClock clock = FixedClock(t0);
    final TemplateRepositoryImpl templates = TemplateRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );
    final TemplateDef stored = _ok(
      await templates.save(aTemplate(fields: const <FieldDef>[serial, name])),
    );
    final String recordId = _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          projectId: const Value<String>('project-1'),
          templateId: Value<String>(stored.id),
          status: const Value<String>('captured'),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>('{}'),
          identityHash: const Value<String>('h1'),
          source: const Value<String>('capture'),
          capturedAt: Value<DateTime>(t0),
          capturedBy: const Value<String>('Ada'),
        ),
        clock: clock,
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(clock),
      ),
    ).id;
    final RecordField value = _ok(
      await insertRecordField(
        db,
        row: RecordFieldsCompanion(
          recordId: Value<String>(recordId),
          fieldKey: const Value<String>('serial'),
          valueRaw: const Value<String>('A-1'),
          source: const Value<String>('typed'),
        ),
        clock: clock,
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(clock),
      ),
    );

    final TemplateDef after = _ok(
      await FieldDeleteAction.apply(
        templates: templates,
        template: stored,
        fieldKey: 'serial',
      ),
    );
    expect(after.fields.map((FieldDef field) => field.fieldKey), <String>[
      'asset_name',
    ]);
    expect(after.fields.single.outputColumn, 'C');

    final List<RecordField> kept = await db.select(db.recordFields).get();
    expect(kept, hasLength(1));
    expect(kept.single.id, value.id);
    expect(kept.single.valueRaw, 'A-1');
    expect(kept.single.fieldKey, 'serial');

    final List<Map<String, Object?>> exported = FieldDeleteAction.exportValues(
      liveFieldKeys: after.fields.map((FieldDef field) => field.fieldKey),
      values: <({String fieldKey, String? value})>[
        (fieldKey: 'serial', value: kept.single.valueRaw),
        (fieldKey: 'asset_name', value: 'Pump'),
      ],
    );
    expect(exported, <Map<String, Object?>>[
      <String, Object?>{'field_key': 'serial', 'value': 'A-1', 'retired': true},
      <String, Object?>{'field_key': 'asset_name', 'value': 'Pump'},
    ]);
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
