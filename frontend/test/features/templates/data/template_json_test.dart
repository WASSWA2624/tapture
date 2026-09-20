import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/data/template_json.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/template_def.dart';
import 'package:tapture/features/templates/domain/template_row.dart';

import '../../../support/factories.dart';
import '../fakes/fake_template_repository.dart';

void main() {
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
    sortOrder: 3,
  );
  const TemplateRow row = TemplateRow(
    identifier: 'm-1',
    label: 'Blood Pressure Machine',
    outputRowNumber: 12,
    aliases: <String>['BP machine', 'bp'],
    metadata: <String, Object?>{'room': 'ward-2'},
    foundStatus: 'found',
  );

  test('export then import keeps every attribute, rows and aliases', () async {
    final TemplateDef original =
        aTemplate(
          id: 'template-src',
          templateKey: 'equipment_asset',
          name: 'Assets',
          version: 5,
          fields: const <FieldDef>[field],
          identityFieldKeys: const <String>['serial_number'],
          rows: const <TemplateRow>[row],
        ).copyWith(
          kind: 'equipment',
          source: 'built',
          sourceFilePath: 'templates/equipment.xlsx',
          sheetName: 'Register',
          headerRow: 2,
          detection: const <String, Object?>{
            'min_columns': 4,
            '_tapture_versions': <Object>[1, 2],
          },
        );

    final Map<String, Object?> json = TemplateJson.encode(original);
    expect(json['schema_version'], TemplateJson.schemaVersion);
    expect(json.containsKey('id'), isFalse);
    expect(json.containsKey('project_id'), isFalse);
    expect(json.containsKey('source_file_path'), isFalse);

    final TemplateDef imported = _ok(
      TemplateJson.decode(jsonEncode(json), projectId: 'project-other'),
    );
    expect(imported.id, isEmpty);
    expect(imported.version, 1);
    expect(imported.projectId, 'project-other');
    expect(imported.source, 'imported');
    expect(imported.sourceFilePath, isNull);
    expect(imported.templateKey, 'equipment_asset');
    expect(imported.name, 'Assets');
    expect(imported.kind, 'equipment');
    expect(imported.sheetName, 'Register');
    expect(imported.headerRow, 2);
    expect(imported.detection, <String, Object?>{'min_columns': 4});
    expect(imported.identityFieldKeys, <String>['serial_number']);
    expect(imported.fields.single, field);
    expect(imported.rows.single, row);
    expect(imported.rows.single.aliases, <String>['BP machine', 'bp']);

    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef first = _ok(await templates.save(imported));
    final TemplateDef second = _ok(await templates.save(imported));
    expect(first.id, isNotEmpty);
    expect(second.id, isNot(first.id));
    expect(first.version, 1);
    expect(second.version, 1);
    expect(templates.count, 2);
    expect(_ok(await templates.byId(first.id))!.name, 'Assets');
  });

  test('an unknown schema version imports nothing', () {
    final Result<TemplateDef> result = TemplateJson.decode(<String, Object?>{
      'schema_version': 2,
      'name': 'Assets',
    }, projectId: 'project-1');
    expect(
      result,
      isA<FailureResult<TemplateDef>>().having(
        (FailureResult<TemplateDef> failure) => failure.failure.message,
        'message',
        Copy.templatesImportUnknownSchema,
      ),
    );
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
