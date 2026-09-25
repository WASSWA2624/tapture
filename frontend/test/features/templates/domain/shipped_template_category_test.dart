import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/shipped_template_category.dart';

void main() {
  test('each shipped template key maps to its listed group', () {
    const Map<String, ShippedTemplateCategory> expected =
        <String, ShippedTemplateCategory>{
          'equipment_asset': ShippedTemplateCategory.assets,
          'medical_equipment': ShippedTemplateCategory.assets,
          'ict_equipment': ShippedTemplateCategory.assets,
          'vehicle_plant': ShippedTemplateCategory.assets,
          'furniture_fitting': ShippedTemplateCategory.assets,
          'building_facility': ShippedTemplateCategory.places,
          'room_space': ShippedTemplateCategory.places,
          'utility_point': ShippedTemplateCategory.places,
          'land_parcel': ShippedTemplateCategory.places,
          'stock_item': ShippedTemplateCategory.operations,
          'inspection_check': ShippedTemplateCategory.operations,
          'work_order': ShippedTemplateCategory.operations,
          'meter_reading': ShippedTemplateCategory.operations,
          'person_beneficiary': ShippedTemplateCategory.people,
          'staff_member': ShippedTemplateCategory.people,
          'household_survey': ShippedTemplateCategory.people,
          'plant_tree': ShippedTemplateCategory.nature,
          'livestock_animal': ShippedTemplateCategory.nature,
          'document_record': ShippedTemplateCategory.records,
          'meeting': ShippedTemplateCategory.records,
          'event_activity': ShippedTemplateCategory.records,
          'incident_report': ShippedTemplateCategory.records,
          'generic_item': ShippedTemplateCategory.general,
        };

    for (final MapEntry<String, ShippedTemplateCategory> entry
        in expected.entries) {
      expect(
        ShippedTemplateCategory.of(entry.key),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('a key the map does not list falls into general, after listed keys', () {
    expect(
      ShippedTemplateCategory.of('something_new'),
      ShippedTemplateCategory.general,
    );
    expect(
      ShippedTemplateCategory.orderOf('something_new'),
      greaterThan(ShippedTemplateCategory.orderOf('generic_item')),
    );
  });

  test('no group is empty and no key is listed twice', () {
    final List<String> keys = <String>[
      for (final ShippedTemplateCategory category
          in ShippedTemplateCategory.values)
        ...category.templateKeys,
    ];
    for (final ShippedTemplateCategory category
        in ShippedTemplateCategory.values) {
      expect(category.templateKeys, isNotEmpty, reason: category.name);
    }
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('every shipped asset is listed in a group', () {
    final List<String> shipped = <String>[
      for (final FileSystemEntity file in Directory(
        'assets/templates',
      ).listSync())
        if (file is File &&
            file.path.endsWith('.json') &&
            !file.uri.pathSegments.last.startsWith('_'))
          (jsonDecode(file.readAsStringSync())
                  as Map<String, Object?>)['template_key']!
              as String,
    ];
    final Set<String> listed = <String>{
      for (final ShippedTemplateCategory category
          in ShippedTemplateCategory.values)
        ...category.templateKeys,
    };
    expect(shipped, hasLength(23));
    for (final String key in shipped) {
      expect(listed, contains(key), reason: key);
    }
  });
}
