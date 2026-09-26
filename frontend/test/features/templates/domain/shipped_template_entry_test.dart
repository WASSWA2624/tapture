import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/shipped_template_category.dart';
import 'package:tapture/features/templates/domain/shipped_template_entry.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

void main() {
  group('a starter entry', () {
    const TemplateDef meter = TemplateDef(
      id: '',
      templateKey: 'meter_reading',
      name: 'templates.meter_reading.name',
      version: 1,
      fields: <FieldDef>[
        FieldDef(
          fieldKey: 'record_uid',
          label: 'templates.groups.record_admin.record_uid',
          type: FieldType.text,
          group: 'record_admin',
        ),
        FieldDef(
          fieldKey: 'site_code',
          label: 'templates.groups.location_context.site_code',
          type: FieldType.text,
          group: 'location_context',
        ),
        FieldDef(
          fieldKey: 'meter_number',
          label: 'templates.meter_reading.meter_number',
          type: FieldType.number,
          group: 'identity',
        ),
        FieldDef(
          fieldKey: 'current_reading_value',
          label: 'templates.meter_reading.current_reading_value',
          type: FieldType.number,
          group: 'reading',
        ),
      ],
      identityFieldKeys: <String>['meter_number'],
      rows: <TemplateRow>[],
      kind: 'meter',
    );

    test('counts every resolved field and searches only its own', () {
      final ShippedTemplateEntry entry = ShippedTemplateEntry.starter(meter);

      expect(entry.templateKey, 'meter_reading');
      expect(entry.kind, 'meter');
      expect(entry.fieldCount, 4);
      expect(entry.fieldKeys, <String>[
        'meter_number',
        'current_reading_value',
      ]);
    });

    test('has no catalogue data and sits in its starter group', () {
      final ShippedTemplateEntry entry = ShippedTemplateEntry.starter(meter);

      expect(entry.isStarter, isTrue);
      expect(entry.title, isNull);
      expect(entry.code, isNull);
      expect(entry.category, isNull);
      expect(entry.recordType, isNull);
      expect(entry.starterCategory, ShippedTemplateCategory.operations);
    });
  });

  test('a catalogue entry is not a starter and keeps its data', () {
    const ShippedTemplateEntry entry = ShippedTemplateEntry(
      templateKey: 'uni_general_observation',
      kind: 'observation',
      fieldCount: 67,
      title: 'General observation',
      code: 'UNI-001',
      category: ShippedCatalogueCategory(
        code: 'UNI',
        title: 'Universal capture and records',
        supergroupCode: '01',
        supergroupTitle: 'Cross-sector foundations',
      ),
      recordType: ShippedRecordType(
        code: 'OBS',
        title: 'Observation / evidence capture',
        kind: 'observation',
      ),
      privacy: 'internal',
      rollout: 'p0',
      fieldKeys: <String>['observation_category', 'observed_details'],
    );

    expect(entry.isStarter, isFalse);
    expect(entry.category!.supergroupTitle, 'Cross-sector foundations');
    expect(entry.recordType!.kind, entry.kind);
    expect(entry.recordType!.capture, isEmpty);
  });
}
