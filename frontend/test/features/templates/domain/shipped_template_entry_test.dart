import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/shipped_template_entry.dart';

void main() {
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

  test('an entry keeps its catalogue data', () {
    expect(entry.templateKey, 'uni_general_observation');
    expect(entry.title, 'General observation');
    expect(entry.code, 'UNI-001');
    expect(entry.fieldCount, 67);
    expect(entry.category.supergroupTitle, 'Cross-sector foundations');
    expect(entry.recordType.kind, entry.kind);
    expect(entry.fieldKeys, <String>[
      'observation_category',
      'observed_details',
    ]);
  });

  test('privacy, tier and own fields default to empty', () {
    const ShippedTemplateEntry bare = ShippedTemplateEntry(
      templateKey: 'log_trip',
      kind: 'log',
      fieldCount: 60,
      title: 'Trip',
      code: 'LOG-001',
      category: ShippedCatalogueCategory(
        code: 'LOG',
        title: 'Logistics freight and distribution',
        supergroupCode: '10',
        supergroupTitle: 'Transport and supply chains',
      ),
      recordType: ShippedRecordType(
        code: 'LOG',
        title: 'Activity / event log',
        kind: 'log',
      ),
    );

    expect(bare.privacy, isEmpty);
    expect(bare.rollout, isEmpty);
    expect(bare.fieldKeys, isEmpty);
  });
}
