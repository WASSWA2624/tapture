import 'dart:convert';
import 'dart:io';

/// Default folder the checker walks when it is given no argument.
const String _defaultDir = 'assets/templates';

/// Schema file that lists the allowed field types and the asset shape.
const String _schemaName = '_schema.json';

/// How to call this, printed when an argument is not a directory.
const String _usage = 'usage: dart run tool/check_templates.dart [directory]';

/// Current schema_version the assets must declare.
const int _schemaVersion = 1;

/// Suggested requiredness values. The user can change any of them (§13.2).
const Set<String> _requiredness = <String>{
  'REQUIRED',
  'RECOMMENDED',
  'OPTIONAL',
};

/// Words an expression may use that are not field keys.
const Set<String> _expressionReserved = <String>{
  'true',
  'false',
  'and',
  'or',
  'not',
  'null',
};

/// Keys that pack more than one fact (§13.1).
const Set<String> _packedKeys = <String>{'make_model', 'address'};

/// Bare money nouns that need a `_currency` companion.
const Set<String> _moneyNouns = <String>{'cost', 'price', 'fee', 'income'};

/// Unit suffixes that make a measured key self-describing.
const List<String> _unitSuffixes = <String>[
  '_mm',
  '_cm',
  '_m',
  '_km',
  '_kg',
  '_g',
  '_sqm',
  '_percent',
  '_c',
  '_f',
  '_w',
  '_kw',
  '_v',
  '_hz',
  '_l',
  '_ml',
  '_ha',
  '_s',
  '_a',
  '_ah',
  '_kva',
  '_ghz',
  '_gb',
  '_inches',
  '_cc',
  '_ntu',
  '_mgl',
  '_cbm',
  '_minutes',
  '_months',
  '_days',
  '_years',
  '_persons',
  '_dpi',
  '_mb',
  '_degrees',
  '_hours',
];

/// Keys that are counts or identifiers, not measurements.
const List<String> _countSuffixes = <String>[
  '_count',
  '_number',
  '_year',
  '_counted',
  '_working',
  '_completed',
  '_plus',
];

/// Boolean keys that do not wear the is_/has_/*_present shape, from §13.5.
const Set<String> _booleanExact = <String>{
  'lockable',
  'habitable',
  'pregnant',
  'lactating',
  'castrated',
  'flowering',
  'fruiting',
  'seeding',
  'developed',
  'scanned',
  'delayed',
  'unanimous',
  'overcrowded',
  'parts_awaited',
  'warranty_claim',
  'estimated_reading',
  'display_legible',
  'repeat_finding',
  'immediate_danger',
  'work_stopped',
  'asset_stopped',
  'legal_hold',
  'vital_record',
  'issued_out',
  'shared_use',
  'adjustable_height',
  'post_established',
  'post_filled',
  'acting_capacity',
  'meter_accessible',
  'within_threshold',
  'age_estimated',
  'id_verified',
  'fingerprint_captured',
  'proxy_authorised',
  'stacked_correctly',
  'fefo_applied',
  'segregated_correctly',
  'vandalism_evident',
  'contamination_risk_nearby',
  'committee_active',
  'caretaker_trained',
  'user_fee_charged',
  'spare_parts_accessible',
  'natural_light_adequate',
  'ceiling_height_adequate',
  'natural_ventilation_adequate',
  'floor_level_even',
  'windscreen_intact',
  'lights_functional',
  'brakes_functional',
  'stability_safe',
  'key_available',
  'domain_joined',
  'ups_connected',
  'os_licence_key_held',
  'bios_password_set',
  'data_wipe_required',
  'ce_fda_marked',
  'manual_available',
  'user_training_provided',
  'calibration_required',
  'ppm_required',
  'requires_water',
  'requires_medical_gas',
  'requires_ups',
  'requires_air_conditioning',
  'solar_installed',
  'sewer_connected',
  'gate_lockable',
  'lift_functional',
  'ramp_gradient_compliant',
  'fire_exit_unobstructed',
  'fire_extinguishers_serviced',
  'water_quality_tested',
  'ecoli_detected',
  'birth_attended_by_skilled',
  'child_immunisation_up_to_date',
  'net_use_last_night',
  'received_aid_last_year',
  'owns_radio',
  'owns_television',
  'owns_mobile_phone',
  'owns_smartphone',
  'owns_refrigerator',
  'owns_bicycle',
  'owns_motorcycle',
  'owns_car',
  'owns_cart',
  'owns_plough',
  'owns_sewing_machine',
  'mobile_money_used',
  'solar_owned',
  'toilet_shared',
  'title_registered',
  'boundary_marked',
  'leaf_colour_normal',
  'vaccination_up_to_date',
  'feed_supplement_used',
  'postmortem_done',
  'ocr_performed',
  'copy_held_elsewhere',
  'agenda_adopted',
  'previous_minutes_confirmed',
  'quorum_met',
  'interpretation_provided',
  'knowledge_assessment_done',
  'report_submitted',
  'first_aid_given',
  'hospitalisation_required',
  'environmental_release_occurred',
  'unsafe_act_identified',
  'unsafe_condition_identified',
  'ppe_in_use',
  'procedure_followed',
  'training_adequate',
  'area_secured',
  'emergency_services_notified',
  'investigation_required',
  'effectiveness_verified',
  'has_attachments',
  'data_subject_present',
  'searchable_text_present',
  'scan_quality_verified',
  'qualification_verified',
  'practising_certificate_present',
  'disciplinary_case_open',
  'training_need_identified',
  'consent_given',
  'photo_consent_given',
  'data_sharing_consent_given',
  'guardian_consent_required',
  'bank_account_present',
  'mobile_money_number_held',
  'chronic_illness_present',
  'assistive_device_used',
  'cold_chain_required',
  'temperature_excursion_recorded',
  'disposal_required',
  'is_critical_requirement',
  'enforcement_notice_issued',
  'follow_up_required',
  'fault_confirmed',
  'external_support_required',
  'recurrence_expected',
  'meter_seal_intact',
  'tamper_suspected',
  'bypass_suspected',
  'anomaly_detected',
  'meter_rollover_occurred',
  'disk_encryption_enabled',
  'remote_management_enabled',
  'touchscreen_present',
  'battery_present',
  'keyboard_present',
  'mouse_present',
  'docking_station_present',
  'printer_shared',
  'spare_tyre_present',
  'jack_present',
  'tool_kit_present',
  'draught_use',
};

/// Top-level keys every asset must carry.
const List<String> _assetKeys = <String>[
  'schema_version',
  'template_key',
  'name',
  'kind',
  'identity_fields',
  'inherits_groups',
  'fields',
  'child_rows',
];

/// Keys every field object must carry.
const List<String> _fieldKeys = <String>[
  'field_key',
  'label',
  'type',
  'required',
];

/// snake_case, starting with a letter.
final RegExp _snakeCase = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

/// `/`, `&`, ` and `, or `+` joining two nouns.
final RegExp _packedPunctuation = RegExp(
  r'/|&| and |[A-Za-z]\+[A-Za-z]',
  caseSensitive: false,
);

/// A field-key shaped word inside `required_when`.
final RegExp _expressionName = RegExp(r'\b[a-z][a-z0-9_]*\b');

/// Checks shipped template assets, printing one line per violation.
///
/// Scans [directory] or `assets/templates/`. Files whose names start with
/// `_` are schema or group lists, not assets. Exits 1 on any violation.
Future<int> main(List<String> args) async {
  final List<String> flags = args
      .where((String argument) => argument.startsWith('-'))
      .toList();
  if (flags.isNotEmpty) {
    stderr.writeln('unrecognised argument(s): ${flags.join(', ')}');
    stderr.writeln(_usage);
    exitCode = 1;
    return exitCode;
  }
  if (args.length > 1) {
    stderr.writeln('unrecognised argument(s): ${args.skip(1).join(', ')}');
    stderr.writeln(_usage);
    exitCode = 1;
    return exitCode;
  }
  final Directory root = Directory(args.isEmpty ? _defaultDir : args.first);
  final List<_Violation> violations = _findViolations(root);
  for (final _Violation violation in violations) {
    stderr.writeln('${violation.file}:${violation.line}: ${violation.message}');
  }
  stdout.writeln(
    violations.isEmpty
        ? 'templates: ${_assetCount(root)} asset(s), all atomic'
        : 'templates: ${violations.length} violation(s)',
  );
  exitCode = violations.isEmpty ? 0 : 1;
  return exitCode;
}

/// One atomicity or schema break, with the file and line that has to change.
typedef _Violation = ({String file, int line, String message});

/// One field as the asset declared it, plus the line its `field_key` sits on.
typedef _Field = ({
  String key,
  String label,
  String type,
  String? requiredWhen,
  String? unit,
  int line,
});

/// A parsed asset, kept so derived templates can see their parent's keys.
typedef _ParsedAsset = ({
  String path,
  String source,
  String templateKey,
  String? derivesFrom,
  List<String> inheritsGroups,
  Map<String, Object?> root,
  List<_Field> fields,
});

/// Reports every way the assets under [root] break the schema or §13.1.
List<_Violation> _findViolations(Directory root) {
  if (!root.existsSync()) {
    return <_Violation>[
      (
        file: _slash(root.path),
        line: 0,
        message: 'there is no directory here to check',
      ),
    ];
  }
  final File schemaFile = _schemaFile(root);
  if (!schemaFile.existsSync()) {
    return <_Violation>[
      (
        file: _display(schemaFile),
        line: 0,
        message: 'the asset schema is missing; shipped templates need it',
      ),
    ];
  }
  final ({Set<String> types, List<_Violation> violations}) schema =
      _readAllowedTypes(schemaFile);
  if (schema.violations.isNotEmpty) {
    return schema.violations;
  }
  final Map<String, Set<String>> groups = _readGroupKeys(root);
  final List<_ParsedAsset> assets = <_ParsedAsset>[];
  final List<_Violation> found = <_Violation>[];
  for (final File file in _assetFiles(root)) {
    final _ParsedAsset? parsed = _parseAsset(file, found);
    if (parsed != null) {
      assets.add(parsed);
    }
  }
  final Map<String, _ParsedAsset> byKey = <String, _ParsedAsset>{
    for (final _ParsedAsset asset in assets) asset.templateKey: asset,
  };
  for (final _ParsedAsset asset in assets) {
    final Set<String> inherited = _inheritedKeys(asset, groups, byKey);
    found.addAll(
      _fieldRuleViolations(
        asset.path,
        asset.source,
        asset.root,
        asset.fields,
        schema.types,
        inherited,
      ),
    );
  }
  return found;
}

/// How many assets [root] holds, ignoring `_*.json`.
int _assetCount(Directory root) {
  if (!root.existsSync()) {
    return 0;
  }
  return _assetFiles(root).length;
}

/// JSON files in [root] that are templates, not schema or group lists.
List<File> _assetFiles(Directory root) {
  final List<File> files = <File>[];
  for (final FileSystemEntity entity in root.listSync()) {
    if (entity is! File) {
      continue;
    }
    final String name = _basename(entity.uri);
    if (!name.endsWith('.json') || name.startsWith('_')) {
      continue;
    }
    files.add(entity);
  }
  files.sort((File a, File b) => _basename(a.uri).compareTo(_basename(b.uri)));
  return files;
}

/// The schema beside [root], or the shipped one under `assets/templates/`.
File _schemaFile(Directory root) {
  final File local = File('${root.path}/$_schemaName');
  if (local.existsSync()) {
    return local;
  }
  return File('$_defaultDir/$_schemaName');
}

/// Allowed `type` names from the schema's field enum.
({Set<String> types, List<_Violation> violations}) _readAllowedTypes(
  File schemaFile,
) {
  final String source = schemaFile.readAsStringSync();
  final Object? decoded = _decode(source);
  if (decoded == null) {
    return (
      types: <String>{},
      violations: <_Violation>[
        (
          file: _display(schemaFile),
          line: 1,
          message: 'the asset schema is not JSON',
        ),
      ],
    );
  }
  final Map<String, Object?>? root = _asMap(decoded);
  final Object? defs = root?[r'$defs'];
  final Map<String, Object?>? field = _asMap(_asMap(defs)?['field']);
  final Map<String, Object?>? properties = _asMap(field?['properties']);
  final Map<String, Object?>? type = _asMap(properties?['type']);
  final Object? raw = type?['enum'];
  if (raw is! List) {
    return (
      types: <String>{},
      violations: <_Violation>[
        (
          file: _display(schemaFile),
          line: _lineOf(source, '"enum"'),
          message: 'the asset schema does not list the registry field types',
        ),
      ],
    );
  }
  final Set<String> types = <String>{
    for (final Object? item in raw)
      if (item is String) item,
  };
  if (types.isEmpty) {
    return (
      types: <String>{},
      violations: <_Violation>[
        (
          file: _display(schemaFile),
          line: _lineOf(source, '"enum"'),
          message: 'the asset schema lists no field types',
        ),
      ],
    );
  }
  return (types: types, violations: <_Violation>[]);
}

/// Field keys declared in `_groups.json`, keyed by group name.
Map<String, Set<String>> _readGroupKeys(Directory root) {
  final File file = File('${root.path}/_groups.json');
  if (!file.existsSync()) {
    final File shipped = File('$_defaultDir/_groups.json');
    if (!shipped.existsSync()) {
      return <String, Set<String>>{};
    }
    return _groupKeysFrom(shipped);
  }
  return _groupKeysFrom(file);
}

Map<String, Set<String>> _groupKeysFrom(File file) {
  final Object? decoded = _decode(file.readAsStringSync());
  final Map<String, Object?>? root = _asMap(decoded);
  if (root == null) {
    return <String, Set<String>>{};
  }
  final Map<String, Set<String>> groups = <String, Set<String>>{};
  for (final MapEntry<String, Object?> entry in root.entries) {
    if (entry.key.startsWith(r'$')) {
      continue;
    }
    final Map<String, Object?>? group = _asMap(entry.value);
    final Object? rawFields = group?['fields'] ?? entry.value;
    if (rawFields is! List) {
      continue;
    }
    final Set<String> keys = <String>{};
    for (final Object? item in rawFields) {
      final Map<String, Object?>? field = _asMap(item);
      final String? key = _asString(field?['field_key']);
      if (key != null) {
        keys.add(key);
      }
    }
    groups[entry.key] = keys;
  }
  return groups;
}

/// Keys this asset inherits from groups and from `derives_from`.
Set<String> _inheritedKeys(
  _ParsedAsset asset,
  Map<String, Set<String>> groups,
  Map<String, _ParsedAsset> byKey,
) {
  final Set<String> keys = <String>{};
  for (final String group in asset.inheritsGroups) {
    keys.addAll(groups[group] ?? const <String>{});
  }
  String? parent = asset.derivesFrom;
  final Set<String> seen = <String>{};
  while (parent != null && seen.add(parent)) {
    final _ParsedAsset? next = byKey[parent];
    if (next == null) {
      break;
    }
    for (final _Field field in next.fields) {
      keys.add(field.key);
    }
    for (final String group in next.inheritsGroups) {
      keys.addAll(groups[group] ?? const <String>{});
    }
    parent = next.derivesFrom;
  }
  return keys;
}

/// Parses one asset and records schema violations. Null when it is not JSON.
_ParsedAsset? _parseAsset(File file, List<_Violation> found) {
  final String source = file.readAsStringSync();
  final String path = _display(file);
  final Object? decoded = _decode(source);
  if (decoded == null) {
    found.add((file: path, line: 1, message: 'the asset is not JSON'));
    return null;
  }
  final Map<String, Object?>? root = _asMap(decoded);
  if (root == null) {
    found.add((file: path, line: 1, message: 'the asset is not an object'));
    return null;
  }
  found.addAll(_schemaViolations(path, source, root));
  final Object? rawFields = root['fields'];
  final List<_Field> fields = <_Field>[];
  if (rawFields is List) {
    for (final Object? item in rawFields) {
      final Map<String, Object?>? map = _asMap(item);
      if (map == null) {
        found.add((
          file: path,
          line: _lineOf(source, '"fields"'),
          message: 'a field is not an object',
        ));
        continue;
      }
      final String key = _asString(map['field_key']) ?? '';
      final int seen = fields.where((_Field field) => field.key == key).length;
      fields.add((
        key: key,
        label: _asString(map['label']) ?? '',
        type: _asString(map['type']) ?? '',
        requiredWhen: _asString(map['required_when']),
        unit: _asString(map['unit']),
        line: _lineOfField(source, key, map, seen),
      ));
    }
  }
  final List<String> inherits = <String>[];
  final Object? rawGroups = root['inherits_groups'];
  if (rawGroups is List) {
    for (final Object? item in rawGroups) {
      if (item is String) {
        inherits.add(item);
      }
    }
  }
  return (
    path: path,
    source: source,
    templateKey: _asString(root['template_key']) ?? _basename(file.uri),
    derivesFrom: _asString(root['derives_from']),
    inheritsGroups: inherits,
    root: root,
    fields: fields,
  );
}

/// Missing or mistyped top-level and per-field schema keys.
Iterable<_Violation> _schemaViolations(
  String path,
  String source,
  Map<String, Object?> root,
) sync* {
  for (final String key in _assetKeys) {
    if (!root.containsKey(key)) {
      yield (file: path, line: 1, message: 'the asset is missing "$key"');
    }
  }
  final Object? version = root['schema_version'];
  if (version != null && version != _schemaVersion) {
    yield (
      file: path,
      line: _lineOf(source, '"schema_version"'),
      message: 'schema_version must be $_schemaVersion',
    );
  }
  if (root['template_key'] != null && root['template_key'] is! String) {
    yield (
      file: path,
      line: _lineOf(source, '"template_key"'),
      message: 'template_key must be a string',
    );
  }
  if (root['name'] != null && root['name'] is! String) {
    yield (
      file: path,
      line: _lineOf(source, '"name"'),
      message: 'name must be a string',
    );
  }
  if (root['kind'] != null && root['kind'] is! String) {
    yield (
      file: path,
      line: _lineOf(source, '"kind"'),
      message: 'kind must be a string',
    );
  }
  if (root['identity_fields'] != null && root['identity_fields'] is! List) {
    yield (
      file: path,
      line: _lineOf(source, '"identity_fields"'),
      message: 'identity_fields must be an array',
    );
  }
  if (root['inherits_groups'] != null && root['inherits_groups'] is! List) {
    yield (
      file: path,
      line: _lineOf(source, '"inherits_groups"'),
      message: 'inherits_groups must be an array',
    );
  }
  if (root['fields'] != null && root['fields'] is! List) {
    yield (
      file: path,
      line: _lineOf(source, '"fields"'),
      message: 'fields must be an array',
    );
  }
  if (root['child_rows'] != null && root['child_rows'] is! List) {
    yield (
      file: path,
      line: _lineOf(source, '"child_rows"'),
      message: 'child_rows must be an array',
    );
  }
  final Object? rawFields = root['fields'];
  if (rawFields is! List) {
    return;
  }
  for (final Object? item in rawFields) {
    final Map<String, Object?>? field = _asMap(item);
    if (field == null) {
      continue;
    }
    final String key = _asString(field['field_key']) ?? '';
    final int line = _lineOfField(source, key, field, 0);
    for (final String name in _fieldKeys) {
      if (!field.containsKey(name)) {
        yield (file: path, line: line, message: 'a field is missing "$name"');
      }
    }
    final String? requiredness = _asString(field['required']);
    if (requiredness != null && !_requiredness.contains(requiredness)) {
      yield (
        file: path,
        line: line,
        message:
            '"required" is a suggested default only and must be REQUIRED, '
            'RECOMMENDED or OPTIONAL (§13.2)',
      );
    }
  }
}

/// §13.1 atomicity rules and the type-registry constraint.
Iterable<_Violation> _fieldRuleViolations(
  String path,
  String source,
  Map<String, Object?> root,
  List<_Field> fields,
  Set<String> allowedTypes,
  Set<String> inherited,
) sync* {
  final Set<String> own = <String>{};
  final Set<String> resolved = <String>{...inherited};
  for (final _Field field in fields) {
    if (field.key.isEmpty) {
      continue;
    }
    if (!own.add(field.key)) {
      yield (
        file: path,
        line: field.line,
        message: 'field_key "${field.key}" is not unique within the template',
      );
    }
    if (inherited.contains(field.key)) {
      yield (
        file: path,
        line: field.line,
        message:
            'field_key "${field.key}" repeats a field from an inherited '
            'group or parent template',
      );
    }
    resolved.add(field.key);
  }

  for (final _Field field in fields) {
    if (field.key.isEmpty) {
      continue;
    }
    if (!_snakeCase.hasMatch(field.key)) {
      yield (
        file: path,
        line: field.line,
        message: 'field_key "${field.key}" is not snake_case',
      );
    }
    if (_packsTwoFacts(field.key, field.label)) {
      yield (
        file: path,
        line: field.line,
        message:
            'field_key "${field.key}" packs two facts into one column (§13.1)',
      );
    }
    if (field.type.isNotEmpty && !allowedTypes.contains(field.type)) {
      yield (
        file: path,
        line: field.line,
        message:
            'type "${field.type}" is not a field type in the registry '
            '(FE-CONS-07)',
      );
    }
    if (_missingUnit(field)) {
      yield (
        file: path,
        line: field.line,
        message:
            'field_key "${field.key}" is measured and has no unit in the '
            'key or in unit',
      );
    }
    if (_isMoney(field) && !resolved.contains(_currencyCompanion(field.key))) {
      yield (
        file: path,
        line: field.line,
        message:
            'field_key "${field.key}" is money and has no '
            '${_currencyCompanion(field.key)} companion',
      );
    }
    if (field.key.endsWith('_refined')) {
      final String raw = '${_stem(field.key, '_refined')}_raw';
      if (!resolved.contains(raw)) {
        yield (
          file: path,
          line: field.line,
          message:
              'field_key "${field.key}" has no $raw companion; the '
              'raw/refined pair must both be declared (§32)',
        );
      }
    }
    if (field.type == 'lookup' && field.key.endsWith('_code')) {
      final String name = '${_stem(field.key, '_code')}_name';
      if (!resolved.contains(name)) {
        yield (
          file: path,
          line: field.line,
          message:
              'field_key "${field.key}" is a lookup code and has no $name '
              'companion',
        );
      }
    }
    if (_isDateType(field.type) && !_isDateKey(field.key)) {
      yield (
        file: path,
        line: field.line,
        message:
            'field_key "${field.key}" is a date and must end in _date or _at',
      );
    }
    if (field.type == 'boolean' && !_isBooleanKey(field.key)) {
      yield (
        file: path,
        line: field.line,
        message:
            'field_key "${field.key}" is a boolean and must be is_*, has_*, '
            '*_present, *_required or *_confirmed',
      );
    }
    yield* _requiredWhenViolations(path, field, resolved);
  }

  final Object? identity = root['identity_fields'];
  if (identity is List) {
    for (final Object? item in identity) {
      if (item is! String) {
        continue;
      }
      if (!resolved.contains(item)) {
        yield (
          file: path,
          line: _lineOf(source, item),
          message:
              'identity_fields names "$item", which the template does not define',
        );
      }
    }
  }
}

/// `required_when` names that are not fields of this template.
Iterable<_Violation> _requiredWhenViolations(
  String path,
  _Field field,
  Set<String> keys,
) sync* {
  final String? expression = field.requiredWhen;
  if (expression == null || expression.trim().isEmpty) {
    return;
  }
  for (final Match match in _expressionName.allMatches(expression)) {
    final String name = match.group(0)!;
    if (_expressionReserved.contains(name) || keys.contains(name)) {
      continue;
    }
    yield (
      file: path,
      line: field.line,
      message:
          'required_when on "${field.key}" names "$name", which the '
          'template does not define',
    );
  }
}

bool _packsTwoFacts(String key, String label) {
  if (_packedKeys.contains(key) || key.contains('_and_')) {
    return true;
  }
  return _packedPunctuation.hasMatch(key) || _packedPunctuation.hasMatch(label);
}

bool _missingUnit(_Field field) {
  if (field.type != 'number' &&
      field.type != 'decimal' &&
      field.type != 'percentage') {
    return false;
  }
  final String? unit = field.unit;
  if (unit != null && unit.trim().isNotEmpty) {
    return false;
  }
  if (_hasSuffix(field.key, _unitSuffixes)) {
    return false;
  }
  if (_hasSuffix(field.key, _countSuffixes) ||
      field.key.startsWith('year_') ||
      field.key.startsWith('quantity_') ||
      field.key.startsWith('males_') ||
      field.key.startsWith('females_') ||
      field.key.startsWith('participants_') ||
      field.key.startsWith('attendees_') ||
      field.key.startsWith('members_')) {
    return false;
  }
  return true;
}

bool _isMoney(_Field field) {
  if (field.key.endsWith('_currency')) {
    return false;
  }
  return field.type == 'currency' ||
      _moneyNouns.contains(field.key) ||
      field.key.endsWith('_amount');
}

String _currencyCompanion(String key) {
  final String prefix = key.endsWith('_amount')
      ? key.substring(0, key.length - '_amount'.length)
      : key;
  return '${prefix}_currency';
}

bool _isDateType(String type) {
  return type == 'date' || type == 'date_time';
}

bool _isDateKey(String key) {
  return key.endsWith('_date') || key.endsWith('_at');
}

bool _isBooleanKey(String key) {
  if (_booleanExact.contains(key)) {
    return true;
  }
  return key.startsWith('is_') ||
      key.startsWith('has_') ||
      key.startsWith('requires_') ||
      key.startsWith('owns_') ||
      key.endsWith('_present') ||
      key.endsWith('_required') ||
      key.endsWith('_confirmed') ||
      key.endsWith('_available') ||
      key.endsWith('_provided') ||
      key.endsWith('_marked') ||
      key.endsWith('_enabled') ||
      key.endsWith('_connected') ||
      key.endsWith('_installed') ||
      key.endsWith('_tested') ||
      key.endsWith('_detected') ||
      key.endsWith('_trained') ||
      key.endsWith('_functional') ||
      key.endsWith('_intact') ||
      key.endsWith('_verified') ||
      key.endsWith('_captured') ||
      key.endsWith('_estimated') ||
      key.endsWith('_occurred') ||
      key.endsWith('_suspected') ||
      key.endsWith('_stopped') ||
      key.endsWith('_given') ||
      key.endsWith('_used') ||
      key.endsWith('_done') ||
      key.endsWith('_owned') ||
      key.endsWith('_submitted') ||
      key.endsWith('_identified') ||
      key.endsWith('_recommended') ||
      key.endsWith('_authorised') ||
      key.endsWith('_accessible') ||
      key.endsWith('_adequate') ||
      key.endsWith('_compliant') ||
      key.endsWith('_unobstructed') ||
      key.endsWith('_serviced') ||
      key.endsWith('_held') ||
      key.endsWith('_joined') ||
      key.endsWith('_set') ||
      key.endsWith('_open') ||
      key.endsWith('_filled') ||
      key.endsWith('_met') ||
      key.endsWith('_adopted') ||
      key.endsWith('_shared') ||
      key.endsWith('_lockable') ||
      key.endsWith('_notified') ||
      key.endsWith('_issued') ||
      key.endsWith('_recorded') ||
      key.endsWith('_performed') ||
      key.endsWith('_followed') ||
      key.endsWith('_secured') ||
      key.endsWith('_normal') ||
      key.endsWith('_registered') ||
      key.endsWith('_externally') ||
      key.endsWith('_elsewhere') ||
      key.endsWith('_even') ||
      key.endsWith('_safe') ||
      key.endsWith('_night') ||
      key.endsWith('_skilled') ||
      key.endsWith('_to_date') ||
      key.endsWith('_expected');
}

bool _hasSuffix(String key, List<String> suffixes) {
  for (final String suffix in suffixes) {
    if (key.endsWith(suffix)) {
      return true;
    }
  }
  return false;
}

String _stem(String key, String suffix) {
  return key.substring(0, key.length - suffix.length);
}

Object? _decode(String source) {
  try {
    return jsonDecode(source);
  } on FormatException {
    return null;
  }
}

Map<String, Object?>? _asMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return <String, Object?>{
      for (final MapEntry<dynamic, dynamic> entry in value.entries)
        entry.key.toString(): entry.value,
    };
  }
  return null;
}

String? _asString(Object? value) {
  if (value is String) {
    return value;
  }
  return null;
}

/// Line of the first occurrence of [needle], or 1 when it is absent.
int _lineOf(String source, String needle) {
  final List<String> lines = source.split('\n');
  for (int index = 0; index < lines.length; index++) {
    if (lines[index].contains(needle)) {
      return index + 1;
    }
  }
  return 1;
}

/// Line of the [occurrence]-th `"field_key": "<key>"` (zero-based).
int _lineOfField(
  String source,
  String key,
  Map<String, Object?> field,
  int occurrence,
) {
  if (key.isNotEmpty) {
    final String needle = '"field_key": "$key"';
    final int line = _lineOfOccurrence(source, needle, occurrence);
    if (source.contains(needle)) {
      return line;
    }
  }
  final String? label = _asString(field['label']);
  if (label != null) {
    return _lineOf(source, label);
  }
  return _lineOf(source, '"fields"');
}

/// Line of the [occurrence]-th [needle] in [source], or 1 when it is absent.
int _lineOfOccurrence(String source, String needle, int occurrence) {
  int seen = 0;
  final List<String> lines = source.split('\n');
  for (int index = 0; index < lines.length; index++) {
    int from = 0;
    while (true) {
      final int at = lines[index].indexOf(needle, from);
      if (at < 0) {
        break;
      }
      if (seen == occurrence) {
        return index + 1;
      }
      seen++;
      from = at + needle.length;
    }
  }
  return 1;
}

String _display(File file) {
  final String full = _slash(file.absolute.path);
  final String cwd = _slash(Directory.current.absolute.path);
  if (full.startsWith('$cwd/')) {
    return full.substring(cwd.length + 1);
  }
  return _basename(file.uri);
}

String _slash(String path) => path.replaceAll(r'\', '/');

String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}
