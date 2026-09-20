import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/features/templates/data/template_mapper.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/template_def.dart';
import 'package:tapture/features/templates/domain/template_row.dart';

void main() {
  test('row → TemplateDef → row keeps every stored attribute', () {
    final DateTime at = DateTime.utc(2026, 9, 20, 8);
    final sqlite.Template header = sqlite.Template(
      id: 'template-1',
      createdAt: at,
      updatedAt: at,
      updatedByDevice: 'device-test',
      rev: 1,
      projectId: 'project-1',
      name: 'Equipment / Asset',
      kind: 'equipment',
      source: 'shipped',
      sourceFilePath: 'templates/equipment.xlsx',
      sheetName: 'Register',
      headerRow: 2,
      identityFields: jsonEncode(<String>['asset_tag', 'serial_number']),
      detection: jsonEncode(<String, Object?>{
        'template_key': 'equipment_asset',
        'min_columns': 4,
        'sheet': 'Register',
      }),
      version: 3,
    );
    final sqlite.TemplateField field = sqlite.TemplateField(
      id: 'field-1',
      createdAt: at,
      updatedAt: at,
      updatedByDevice: 'device-test',
      rev: 1,
      templateId: header.id,
      fieldKey: 'serial_number',
      label: 'Serial number',
      type: 'long_text',
      outputColumn: 'B',
      isRequired: false,
      inputMode: 'MANUAL_ONLY',
      stickable: true,
      contextLevel: 2,
      autoFill: true,
      defaultValue: 'n/a',
      options: jsonEncode(<Object>[
        <String, Object?>{'code': 'A', 'label': 'Excellent'},
        'Other',
      ]),
      unit: 'kg',
      validation: jsonEncode(<String, Object?>{
        'pattern': r'^[A-Z0-9-]+$',
        'message': 'Use letters, digits or a hyphen.',
        '_tapture': <String, Object?>{
          'helpText': 'Stamped on the plate.',
          'requiredWhen': 'fault_present == true',
          'hidden': true,
          'group': 'identity',
          'identity': true,
          'requiredness': 'RECOMMENDED',
          'autoFill': 'TODAY',
        },
      }),
      lookup: jsonEncode(<String, Object?>{
        'datasetId': 'suppliers',
        'keyColumn': 'name',
      }),
      refine: true,
      sortOrder: 4,
    );
    final sqlite.TemplateRow row = sqlite.TemplateRow(
      id: 'row-1',
      createdAt: at,
      updatedAt: at,
      updatedByDevice: 'device-test',
      rev: 1,
      templateId: header.id,
      outputRowNumber: 12,
      identifier: 'm-1',
      label: 'Blood Pressure Machine',
      aliases: jsonEncode(<String>['BP machine', 'BP']),
      metadata: jsonEncode(<String, Object?>{'room': 'ward-2'}),
      foundStatus: 'found',
    );

    final TemplateDef template = TemplateMapper.fromRows(
      header: header,
      fields: <sqlite.TemplateField>[field],
      rows: <sqlite.TemplateRow>[row],
    );

    expect(template.id, header.id);
    expect(template.templateKey, 'equipment_asset');
    expect(template.name, header.name);
    expect(template.version, 3);
    expect(template.projectId, 'project-1');
    expect(template.kind, 'equipment');
    expect(template.source, 'shipped');
    expect(template.sourceFilePath, 'templates/equipment.xlsx');
    expect(template.sheetName, 'Register');
    expect(template.headerRow, 2);
    expect(template.identityFieldKeys, <String>['asset_tag', 'serial_number']);
    expect(template.detection, <String, Object?>{
      'min_columns': 4,
      'sheet': 'Register',
    });

    final FieldDef mapped = template.fields.single;
    expect(mapped.fieldKey, 'serial_number');
    expect(mapped.label, 'Serial number');
    expect(mapped.type, FieldType.longText);
    expect(mapped.requiredness, Requiredness.recommended);
    expect(mapped.defaultValue, 'n/a');
    expect(mapped.unit, 'kg');
    expect(mapped.helpText, 'Stamped on the plate.');
    expect(mapped.inputMode, InputMode.manualOnly);
    expect(mapped.stickable, isTrue);
    expect(mapped.contextLevel, 2);
    expect(mapped.autoFill, AutoFill.today);
    expect(mapped.refine, isTrue);
    expect(mapped.options, <Object>[
      <String, Object?>{'code': 'A', 'label': 'Excellent'},
      'Other',
    ]);
    expect(mapped.group, 'identity');
    expect(mapped.outputColumn, 'B');
    expect(mapped.requiredWhen, 'fault_present == true');
    expect(mapped.hidden, isTrue);
    expect(mapped.identity, isTrue);
    expect(mapped.validation, <String, Object?>{
      'pattern': r'^[A-Z0-9-]+$',
      'message': 'Use letters, digits or a hyphen.',
    });
    expect(mapped.lookup, <String, Object?>{
      'datasetId': 'suppliers',
      'keyColumn': 'name',
    });
    expect(mapped.sortOrder, 4);

    final TemplateRow mappedRow = template.rows.single;
    expect(mappedRow.identifier, 'm-1');
    expect(mappedRow.label, 'Blood Pressure Machine');
    expect(mappedRow.outputRowNumber, 12);
    expect(mappedRow.aliases, <String>['BP machine', 'BP']);
    expect(mappedRow.metadata, <String, Object?>{'room': 'ward-2'});
    expect(mappedRow.foundStatus, 'found');

    final sqlite.TemplatesCompanion headerOut = TemplateMapper.headerToRow(
      template,
    );
    expect(headerOut.id.value, header.id);
    expect(headerOut.projectId.value, header.projectId);
    expect(headerOut.name.value, header.name);
    expect(headerOut.kind.value, header.kind);
    expect(headerOut.source.value, header.source);
    expect(headerOut.sourceFilePath.value, header.sourceFilePath);
    expect(headerOut.sheetName.value, header.sheetName);
    expect(headerOut.headerRow.value, header.headerRow);
    expect(headerOut.version.value, header.version);
    expect(jsonDecode(headerOut.identityFields.value), <Object>[
      'asset_tag',
      'serial_number',
    ]);
    expect(jsonDecode(headerOut.detection.value), <String, Object?>{
      'min_columns': 4,
      'sheet': 'Register',
      'template_key': 'equipment_asset',
    });

    final sqlite.TemplateFieldsCompanion fieldOut = TemplateMapper.fieldToRow(
      mapped,
      templateId: header.id,
      id: field.id,
    );
    expect(fieldOut.id.value, field.id);
    expect(fieldOut.templateId.value, header.id);
    expect(fieldOut.fieldKey.value, field.fieldKey);
    expect(fieldOut.label.value, field.label);
    expect(fieldOut.type.value, 'long_text');
    expect(fieldOut.outputColumn.value, field.outputColumn);
    expect(fieldOut.isRequired.value, isFalse);
    expect(fieldOut.inputMode.value, 'MANUAL_ONLY');
    expect(fieldOut.stickable.value, isTrue);
    expect(fieldOut.contextLevel.value, 2);
    expect(fieldOut.autoFill.value, isTrue);
    expect(fieldOut.defaultValue.value, field.defaultValue);
    expect(fieldOut.unit.value, field.unit);
    expect(fieldOut.refine.value, isTrue);
    expect(fieldOut.sortOrder.value, 4);
    expect(jsonDecode(fieldOut.options.value), <Object>[
      <String, Object?>{'code': 'A', 'label': 'Excellent'},
      'Other',
    ]);
    expect(jsonDecode(fieldOut.lookup.value), <String, Object?>{
      'datasetId': 'suppliers',
      'keyColumn': 'name',
    });
    expect(jsonDecode(fieldOut.validation.value), <String, Object?>{
      'pattern': r'^[A-Z0-9-]+$',
      'message': 'Use letters, digits or a hyphen.',
      '_tapture': <String, Object?>{
        'helpText': 'Stamped on the plate.',
        'requiredWhen': 'fault_present == true',
        'hidden': true,
        'group': 'identity',
        'identity': true,
        'requiredness': 'RECOMMENDED',
        'autoFill': 'TODAY',
      },
    });

    final sqlite.TemplateRowsCompanion rowOut = TemplateMapper.rowToRow(
      mappedRow,
      templateId: header.id,
      id: row.id,
    );
    expect(rowOut.identifier.value, row.identifier);
    expect(rowOut.label.value, row.label);
    expect(rowOut.outputRowNumber.value, 12);
    expect(rowOut.foundStatus.value, 'found');
    expect(jsonDecode(rowOut.aliases.value), <Object>['BP machine', 'BP']);
    expect(jsonDecode(rowOut.metadata.value), <String, Object?>{
      'room': 'ward-2',
    });

    final sqlite.Template writtenHeader = header.copyWithCompanion(headerOut);
    final sqlite.TemplateField writtenField = field.copyWithCompanion(fieldOut);
    final sqlite.TemplateRow writtenRow = row.copyWithCompanion(rowOut);
    expect(
      TemplateMapper.fromRows(
        header: writtenHeader,
        fields: <sqlite.TemplateField>[writtenField],
        rows: <sqlite.TemplateRow>[writtenRow],
      ),
      template,
    );
  });

  test('requiredness is three values, never a bool', () {
    expect(Requiredness.values, <Requiredness>[
      Requiredness.required,
      Requiredness.recommended,
      Requiredness.optional,
    ]);
    expect(
      TemplateMapper.fieldFromRow(_field(isRequired: true)).requiredness,
      Requiredness.required,
    );
    expect(
      TemplateMapper.fieldFromRow(_field(isRequired: false)).requiredness,
      Requiredness.optional,
    );
  });

  test('an empty input mode and type load as ANY and text', () {
    final FieldDef field = TemplateMapper.fieldFromRow(
      _field(type: '', inputMode: '', autoFill: true),
    );
    expect(field.type, FieldType.text);
    expect(field.inputMode, InputMode.any);
    expect(field.autoFill, AutoFill.context);
  });
}

sqlite.TemplateField _field({
  bool isRequired = false,
  String type = 'text',
  String inputMode = '',
  bool autoFill = false,
}) {
  final DateTime at = DateTime.utc(2026, 9, 20, 8);
  return sqlite.TemplateField(
    id: 'field-1',
    createdAt: at,
    updatedAt: at,
    updatedByDevice: 'device-test',
    rev: 1,
    templateId: 'template-1',
    fieldKey: 'serial',
    label: 'Serial',
    type: type,
    outputColumn: null,
    isRequired: isRequired,
    inputMode: inputMode,
    stickable: false,
    contextLevel: null,
    autoFill: autoFill,
    defaultValue: null,
    options: '[]',
    unit: null,
    validation: '{}',
    lookup: '{}',
    refine: false,
    sortOrder: 0,
  );
}
