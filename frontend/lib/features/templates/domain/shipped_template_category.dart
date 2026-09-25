/// The groups the shipped library is listed under.
///
/// Every shipped template has a `kind` of its own, so kinds cannot group the
/// library. This map is the grouping; the shipped assets stay as they are.
enum ShippedTemplateCategory {
  /// Registers of equipment and other fixed assets.
  assets(<String>[
    'equipment_asset',
    'medical_equipment',
    'ict_equipment',
    'vehicle_plant',
    'furniture_fitting',
  ]),

  /// Buildings, rooms, service points and land.
  places(<String>[
    'building_facility',
    'room_space',
    'utility_point',
    'land_parcel',
  ]),

  /// Stock counts, inspections, maintenance and meter readings.
  operations(<String>[
    'stock_item',
    'inspection_check',
    'work_order',
    'meter_reading',
  ]),

  /// People, staff and households.
  people(<String>['person_beneficiary', 'staff_member', 'household_survey']),

  /// Plants, trees and animals.
  nature(<String>['plant_tree', 'livestock_animal']),

  /// Documents, meetings, events and incidents.
  records(<String>[
    'document_record',
    'meeting',
    'event_activity',
    'incident_report',
  ]),

  /// Anything else, including a key this map does not list.
  general(<String>['generic_item']);

  const ShippedTemplateCategory(this.templateKeys);

  /// Template keys in this group, in the order they are listed.
  final List<String> templateKeys;

  /// The group [templateKey] is listed under; [general] when unlisted.
  static ShippedTemplateCategory of(String templateKey) {
    for (final ShippedTemplateCategory category in values) {
      if (category.templateKeys.contains(templateKey)) {
        return category;
      }
    }
    return general;
  }

  /// Listing position of [templateKey] inside its group. Unlisted keys sort
  /// after every listed one.
  static int orderOf(String templateKey) {
    final int index = of(templateKey).templateKeys.indexOf(templateKey);
    return index < 0 ? _unlisted : index;
  }
}

/// Places unlisted keys after listed ones without a magic number at the call
/// site (FE-CODE-09).
const int _unlisted = 1 << 20;
