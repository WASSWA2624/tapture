import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/core/import/import.dart';
import 'package:tapture/features/reference/reference.dart';
import 'package:tapture/features/templates/presentation/checklist_screen.dart';
import 'package:tapture/features/templates/presentation/detection_profile_screen.dart';
import 'package:tapture/features/templates/presentation/field_add_sheet.dart';
import 'package:tapture/features/templates/presentation/field_list_screen.dart';
import 'package:tapture/features/templates/presentation/identity_fields_screen.dart';
import 'package:tapture/features/templates/presentation/lookup_binding_screen.dart';
import 'package:tapture/features/templates/presentation/output_mapping_screen.dart';
import 'package:tapture/features/templates/presentation/required_columns_screen.dart';
import 'package:tapture/features/templates/presentation/row_aliases_screen.dart';
import 'package:tapture/features/templates/presentation/shipped_picker_screen.dart';
import 'package:tapture/features/templates/presentation/template_create_screen.dart';
import 'package:tapture/features/templates/presentation/template_import_action.dart';
import 'package:tapture/features/templates/presentation/template_import_controller.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';
import 'package:tapture/features/templates/presentation/template_migration_screen.dart';
import 'package:tapture/features/templates/presentation/xlsx_mapping_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../fakes/fake_template_repository.dart';

List<({String name, Widget screen, bool preview})>
sectionedViews() => <({String name, Widget screen, bool preview})>[
  (
    name: 'Create',
    screen: const TemplateCreateScreen(projectId: 'project'),
    preview: false,
  ),
  (
    name: 'Project templates',
    screen: const TemplateListScreen(projectId: 'project'),
    preview: false,
  ),
  (
    name: 'Fields',
    screen: const FieldListScreen(templateId: 'template'),
    preview: false,
  ),
  (
    name: 'Defaults and sources',
    screen: const FieldListScreen(templateId: 'template', showAdvanced: true),
    preview: false,
  ),
  (
    name: 'Field source editor',
    screen: const FieldAddSheet(
      templateId: 'template',
      fieldKey: 'serial',
      showAdvanced: true,
    ),
    preview: false,
  ),
  (
    name: 'Library',
    screen: const ShippedPickerScreen(projectId: 'project'),
    preview: false,
  ),
  (name: 'Shipped preview', screen: const ShippedPickerScreen(), preview: true),
  (
    name: 'Required columns',
    screen: const RequiredColumnsScreen(templateId: 'template'),
    preview: false,
  ),
  (
    name: 'Identity',
    screen: const IdentityFieldsScreen(templateId: 'template'),
    preview: false,
  ),
  (
    name: 'Output',
    screen: const OutputMappingScreen(templateId: 'template'),
    preview: false,
  ),
  (
    name: 'Migration',
    screen: const TemplateMigrationScreen(templateId: 'template'),
    preview: false,
  ),
  (
    name: 'Aliases',
    screen: const RowAliasesScreen(templateId: 'template'),
    preview: false,
  ),
  (
    name: 'Checklist',
    screen: const ChecklistScreen(templateId: 'template'),
    preview: false,
  ),
  (
    name: 'Detection',
    screen: const DetectionProfileScreen(templateId: 'template'),
    preview: false,
  ),
  (
    name: 'Lookup',
    screen: const LookupBindingScreen(
      templateId: 'template',
      fieldKey: 'serial',
    ),
    preview: false,
  ),
  (
    name: 'Spreadsheet mapping',
    screen: XlsxMappingScreen(
      path: 'fixture.csv',
      project: aProject(id: 'project'),
    ),
    preview: false,
  ),
  (
    name: 'Import preview',
    screen: const TemplateImportAction(projectId: 'project'),
    preview: false,
  ),
];

List<Override> sectionedOverrides(FakeTemplateRepository templates) =>
    <Override>[
      templateRepositoryProvider.overrideWithValue(templates),
      templateRecordCountsProvider.overrideWith(
        (Ref _, String _) => const <String, int>{'template': 2},
      ),
      shippedLibraryProvider.overrideWith(
        (Ref _) async => const <ShippedTemplateEntry>[_catalogue],
      ),
      shippedTemplateProvider.overrideWith(
        (Ref _, String _) async => sectionedTemplate(),
      ),
      templateCapturedRecordsProvider.overrideWith(
        (Ref _, String _) => Stream<List<CapturedTemplateRecord>>.value(
          const <CapturedTemplateRecord>[
            (
              id: 'record',
              templateVersion: 0,
              fields: <String, String>{'retired': 'Kept evidence'},
              retired: <String>{},
            ),
          ],
        ),
      ),
      datasetListProvider.overrideWith(
        (Ref _, String _) =>
            Stream<List<ReferenceDataset>>.value(<ReferenceDataset>[
              ReferenceDataset(
                id: 'register',
                name: 'Equipment register with manufacturer identifiers',
                keyColumn: 'serial',
                columns: const <String>['serial', 'name'],
                source: DatasetSource.device,
                importedAt: DateTime.utc(2026, 10, 13),
                rowCount: 2,
                projectId: 'project',
              ),
            ]),
      ),
      xlsxWorkbookProvider.overrideWith((Ref _, Object _) async => _workbook),
      templateImportControllerProvider.overrideWithBuild(
        (Ref _, TemplateImportController _) async => sectionedTemplate(),
      ),
    ];

TemplateDef sectionedTemplate() => aTemplate(
  id: 'template',
  projectId: 'project',
  templateKey: 'sectioned_equipment',
  name: sectionedTemplateName,
  fields: const <FieldDef>[
    FieldDef(
      fieldKey: 'serial',
      label: _fieldLabel,
      type: FieldType.lookup,
      lookup: <String, Object?>{
        'dataset': 'register',
        'match_on': <String>['serial'],
        'fills': <String, String>{'name': 'name'},
      },
      validation: <String, Object?>{'pattern': r'^[A-Z0-9]+$'},
    ),
    FieldDef(
      fieldKey: 'name',
      label: 'Manufacturer name on the equipment identification plate',
      type: FieldType.text,
      group: 'record_admin',
    ),
  ],
  rows: const <TemplateRow>[
    TemplateRow(
      identifier: 'asset',
      label: 'Portable diagnostic equipment in the outpatient department',
      outputRowNumber: 2,
      aliases: <String>['Diagnostic unit'],
      metadata: <String, Object?>{'context': 'Outpatient department'},
    ),
  ],
);

const String sectionedTemplateName =
    'Equipment identification and maintenance inspection';
const String _fieldLabel = 'Serial number on the equipment manufacturer label';

const ShippedTemplateEntry _catalogue = ShippedTemplateEntry(
  templateKey: 'sectioned_equipment',
  kind: 'asset',
  fieldCount: 2,
  title: sectionedTemplateName,
  code: 'EQ-001',
  category: ShippedCatalogueCategory(
    code: 'EQ',
    title: 'Equipment inspection and maintenance',
    supergroupCode: '01',
    supergroupTitle: 'Cross-sector equipment and service operations',
  ),
  recordType: ShippedRecordType(
    code: 'ASSET',
    title: 'Equipment identification and inspection',
    kind: 'asset',
  ),
  privacy: 'internal',
  rollout: 'p0',
);

const WorkbookSnapshot _workbook = (
  sheets: <WorkbookSheet>[
    (
      name: 'Equipment',
      rowCount: 2,
      columnCount: 1,
      usedRange: 'A1:A2',
      mergedCells: <String>[],
      rows: <List<String>>[
        <String>[_fieldLabel],
        <String>['A-001'],
      ],
      header: (rowNumber: 1, labels: <String>[_fieldLabel], isSuggestion: true),
      columns: <ColumnSuggestion>[
        (
          header: _fieldLabel,
          typeName: 'text',
          unit: null,
          options: <String>[],
          isSuggestion: true,
        ),
      ],
    ),
  ],
);
