import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' hide TemplateRow;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

import '../../../support/factories.dart';
import '../template_repository_contract.dart';

void main() {
  late AppDatabase db;
  late TemplateRepositoryImpl repo;

  final DateTime t0 = DateTime.utc(2026, 9, 20, 8);
  final FixedClock clock = FixedClock(t0);

  setUp(() {
    db = AppDatabase.memory();
    repo = TemplateRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );
  });

  tearDown(() async {
    await db.close();
  });

  runTemplateRepositoryContract(() => repo);

  test('save round-trips every §12.2 attribute against the database', () async {
    const FieldDef field = FieldDef(
      fieldKey: 'serial_number',
      label: 'Serial number',
      type: FieldType.longText,
      requiredness: Requiredness.recommended,
      defaultValue: 'n/a',
      unit: 'kg',
      helpText: 'Stamped on the plate.',
      inputMode: InputMode.manualOnly,
      stickable: true,
      contextLevel: 2,
      autoFill: AutoFill.today,
      refine: true,
      options: <Object>[
        <String, Object?>{'code': 'A', 'label': 'Excellent'},
        'Other',
      ],
      group: 'identity',
      outputColumn: 'B',
      requiredWhen: 'fault_present == true',
      hidden: true,
      identity: true,
      validation: <String, Object?>{
        'pattern': r'^[A-Z0-9-]+$',
        'message': 'Use letters, digits or a hyphen.',
      },
      lookup: <String, Object?>{'datasetId': 'suppliers', 'keyColumn': 'name'},
    );
    const TemplateRow row = TemplateRow(
      identifier: 'm-1',
      label: 'Blood Pressure Machine',
      outputRowNumber: 12,
      aliases: <String>['BP machine'],
      metadata: <String, Object?>{'room': 'ward-2'},
      foundStatus: 'found',
    );
    final TemplateDef stored = _ok(
      await repo.save(
        aTemplate(
          templateKey: 'equipment_asset',
          fields: <FieldDef>[field],
          identityFieldKeys: <String>['serial_number'],
          rows: <TemplateRow>[row],
        ).copyWith(
          kind: 'equipment',
          source: 'imported',
          sourceFilePath: 'templates/equipment.xlsx',
          sheetName: 'Register',
          headerRow: 2,
          detection: const <String, Object?>{'min_columns': 4},
        ),
      ),
    );

    expect(stored.templateKey, 'equipment_asset');
    expect(stored.kind, 'equipment');
    expect(stored.source, 'imported');
    expect(stored.sourceFilePath, 'templates/equipment.xlsx');
    expect(stored.sheetName, 'Register');
    expect(stored.headerRow, 2);
    expect(stored.detection, <String, Object?>{'min_columns': 4});
    expect(stored.identityFieldKeys, <String>['serial_number']);
    expect(stored.fields.single, field.copyWith(sortOrder: 0));
    expect(stored.rows.single, row);

    final TemplateDef? loaded = _ok(await repo.byId(stored.id));
    expect(loaded, stored);
  });

  test('a removed field is gone on the next read', () async {
    final TemplateDef first = _ok(
      await repo.save(
        aTemplate(
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
            FieldDef(fieldKey: 'make', label: 'Make', type: FieldType.text),
          ],
        ),
      ),
    );
    final TemplateDef second = _ok(
      await repo.save(first.copyWith(fields: <FieldDef>[first.fields.first])),
    );
    expect(second.fields.map((FieldDef field) => field.fieldKey), <String>[
      'serial',
    ]);
  });

  test('a shipped template is not listed on a project watch', () async {
    final TemplateDef draft = aTemplate(name: 'Library');
    _ok(
      await repo.save(
        TemplateDef(
          id: draft.id,
          templateKey: draft.templateKey,
          name: draft.name,
          version: draft.version,
          fields: draft.fields,
          identityFieldKeys: draft.identityFieldKeys,
          rows: draft.rows,
          kind: draft.kind,
          source: 'shipped',
        ),
      ),
    );
    expect(await repo.watchByProject('p1').first, isEmpty);
    expect(_ok(await repo.byId(draft.id))?.projectId, isNull);
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
