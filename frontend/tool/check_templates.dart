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
];

/// Keys that are counts or identifiers, not measurements.
const List<String> _countSuffixes = <String>['_count', '_number', '_year'];

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
  final List<_Violation> found = <_Violation>[];
  for (final File file in _assetFiles(root)) {
    found.addAll(_checkAsset(file, schema.types));
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

/// Schema and atomicity findings for one asset.
Iterable<_Violation> _checkAsset(File file, Set<String> allowedTypes) sync* {
  final String source = file.readAsStringSync();
  final String path = _display(file);
  final Object? decoded = _decode(source);
  if (decoded == null) {
    yield (file: path, line: 1, message: 'the asset is not JSON');
    return;
  }
  final Map<String, Object?>? root = _asMap(decoded);
  if (root == null) {
    yield (file: path, line: 1, message: 'the asset is not an object');
    return;
  }
  yield* _schemaViolations(path, source, root);
  final Object? rawFields = root['fields'];
  if (rawFields is! List) {
    return;
  }
  final List<_Field> fields = <_Field>[];
  for (final Object? item in rawFields) {
    final Map<String, Object?>? map = _asMap(item);
    if (map == null) {
      yield (
        file: path,
        line: _lineOf(source, '"fields"'),
        message: 'a field is not an object',
      );
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
  yield* _fieldRuleViolations(path, source, root, fields, allowedTypes);
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
) sync* {
  final Set<String> keys = <String>{};
  final Map<String, _Field> byKey = <String, _Field>{};
  for (final _Field field in fields) {
    if (field.key.isEmpty) {
      continue;
    }
    if (!keys.add(field.key)) {
      yield (
        file: path,
        line: field.line,
        message: 'field_key "${field.key}" is not unique within the template',
      );
    }
    byKey[field.key] = field;
  }

  final bool hasLookup = fields.any((_Field field) => field.type == 'lookup');

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
    if (_isMoney(field) && !byKey.containsKey(_currencyCompanion(field.key))) {
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
      if (!byKey.containsKey(raw)) {
        yield (
          file: path,
          line: field.line,
          message:
              'field_key "${field.key}" has no $raw companion; the '
              'raw/refined pair must both be declared (§32)',
        );
      }
    }
    if (hasLookup && field.key.endsWith('_code')) {
      final String name = '${_stem(field.key, '_code')}_name';
      if (!byKey.containsKey(name)) {
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
    yield* _requiredWhenViolations(path, field, keys);
  }

  final Object? identity = root['identity_fields'];
  if (identity is List) {
    for (final Object? item in identity) {
      if (item is! String) {
        continue;
      }
      if (!keys.contains(item)) {
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
  if (_hasSuffix(field.key, _countSuffixes) || field.key.startsWith('year_')) {
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
  return key.startsWith('is_') ||
      key.startsWith('has_') ||
      key.endsWith('_present') ||
      key.endsWith('_required') ||
      key.endsWith('_confirmed');
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
