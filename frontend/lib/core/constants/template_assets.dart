/// Typed paths for the shipped template library (FE-STR-12).
abstract final class TemplateAssets {
  /// JSON Schema every shipped template asset must satisfy.
  static const String schema = 'assets/templates/_schema.json';

  /// The four inherited groups of specification §13.3.
  static const String groups = 'assets/templates/_groups.json';

  /// Equipment / Asset.
  static const String equipmentAsset = 'assets/templates/equipment_asset.json';

  /// Medical Equipment, derived from [equipmentAsset].
  static const String medicalEquipment =
      'assets/templates/medical_equipment.json';

  /// ICT Equipment, derived from [equipmentAsset].
  static const String ictEquipment = 'assets/templates/ict_equipment.json';

  /// Vehicle / Plant, derived from [equipmentAsset].
  static const String vehiclePlant = 'assets/templates/vehicle_plant.json';

  /// Furniture & Fittings, derived from [equipmentAsset].
  static const String furnitureFitting =
      'assets/templates/furniture_fitting.json';

  /// Building / Facility.
  static const String buildingFacility =
      'assets/templates/building_facility.json';

  /// Room / Space.
  static const String roomSpace = 'assets/templates/room_space.json';

  /// Utility / Service Point.
  static const String utilityPoint = 'assets/templates/utility_point.json';

  /// Stock / Store Item.
  static const String stockItem = 'assets/templates/stock_item.json';

  /// Inspection / Compliance.
  static const String inspectionCheck =
      'assets/templates/inspection_check.json';

  /// Maintenance / Work Order.
  static const String workOrder = 'assets/templates/work_order.json';

  /// Meter Reading.
  static const String meterReading = 'assets/templates/meter_reading.json';

  /// Person / Beneficiary.
  static const String personBeneficiary =
      'assets/templates/person_beneficiary.json';

  /// Staff / Workforce.
  static const String staffMember = 'assets/templates/staff_member.json';

  /// Household / Dwelling.
  static const String householdSurvey =
      'assets/templates/household_survey.json';

  /// Land / Plot / Parcel.
  static const String landParcel = 'assets/templates/land_parcel.json';

  /// Plant / Tree Survey.
  static const String plantTree = 'assets/templates/plant_tree.json';

  /// Livestock / Animal.
  static const String livestockAnimal =
      'assets/templates/livestock_animal.json';

  /// Document / Archive Record.
  static const String documentRecord = 'assets/templates/document_record.json';

  /// Meeting, with child rows for agenda, attendance, decisions and actions.
  static const String meeting = 'assets/templates/meeting.json';

  /// Event / Activity.
  static const String eventActivity = 'assets/templates/event_activity.json';

  /// Incident / Issue.
  static const String incidentReport = 'assets/templates/incident_report.json';

  /// Generic Item — ten columns, one required, so capture can start immediately.
  static const String genericItem = 'assets/templates/generic_item.json';

  /// Every shipped template asset, in specification §13.4 order.
  static const List<String> library = <String>[
    equipmentAsset,
    medicalEquipment,
    ictEquipment,
    vehiclePlant,
    furnitureFitting,
    buildingFacility,
    roomSpace,
    utilityPoint,
    stockItem,
    inspectionCheck,
    workOrder,
    meterReading,
    personBeneficiary,
    staffMember,
    householdSurvey,
    landParcel,
    plantTree,
    livestockAnimal,
    documentRecord,
    meeting,
    eventActivity,
    incidentReport,
    genericItem,
  ];
}
