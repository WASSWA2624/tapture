import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/template_assets.dart';

void main() {
  late Map<String, Object?> schema;
  late Map<String, Set<String>> groupKeys;
  late Map<String, Map<String, Object?>> assets;

  setUpAll(() {
    schema = _asObject(File(TemplateAssets.schema).readAsStringSync());
    groupKeys = _groupKeys(File(TemplateAssets.groups).readAsStringSync());
    assets = <String, Map<String, Object?>>{
      for (final String path in TemplateAssets.library)
        path: _asObject(File(path).readAsStringSync()),
    };
  });

  test('every asset parses, validates against the schema, and resolves '
      'inherited groups and identity keys', () {
    expect(TemplateAssets.library, hasLength(23));
    expect(assets, hasLength(23));
    expect(groupKeys.keys, <String>[
      'record_admin',
      'location_context',
      'evidence',
      'review',
    ]);

    final Set<String> allowedTypes = _enumAt(schema, <String>[
      r'$defs',
      'field',
      'properties',
      'type',
      'enum',
    ]);
    final List<String> requiredAssetKeys = _stringList(schema['required']);
    final List<String> requiredFieldKeys = _stringList(
      _asObject(_asObject(schema[r'$defs'])['field'])['required'],
    );
    expect(requiredAssetKeys, isNotEmpty);
    expect(requiredFieldKeys, <String>[
      'field_key',
      'label',
      'type',
      'required',
    ]);

    final Map<String, Map<String, Object?>> byKey =
        <String, Map<String, Object?>>{
          for (final Map<String, Object?> asset in assets.values)
            _asString(asset['template_key']): asset,
        };

    for (final MapEntry<String, Map<String, Object?>> entry in assets.entries) {
      final Map<String, Object?> asset = entry.value;
      _expectSchema(
        entry.key,
        asset,
        requiredAssetKeys,
        requiredFieldKeys,
        allowedTypes,
      );

      final Set<String> inherited = _inheritedKeys(asset, groupKeys, byKey);
      final Set<String> own = _fieldKeys(asset);
      expect(
        own.intersection(inherited),
        isEmpty,
        reason: '${asset['template_key']} repeats an inherited field',
      );

      for (final String key in _stringList(asset['identity_fields'])) {
        expect(
          own.contains(key) || inherited.contains(key),
          isTrue,
          reason:
              '${asset['template_key']} identity_fields names "$key", '
              'which groups and the asset do not resolve',
        );
      }
    }
  });

  test('generic_item has ten columns and one required field', () {
    final Map<String, Object?> asset = assets[TemplateAssets.genericItem]!;
    final List<Map<String, Object?>> fields = _fields(asset);
    expect(fields, hasLength(10));
    expect(
      fields.where(
        (Map<String, Object?> field) => field['required'] == 'REQUIRED',
      ),
      hasLength(1),
    );
    expect(
      fields.singleWhere(
        (Map<String, Object?> field) => field['required'] == 'REQUIRED',
      )['field_key'],
      'item_name',
    );
  });

  test(
    'the four equipment children reuse the parent instead of duplicating it',
    () {
      expect(
        assets[TemplateAssets.medicalEquipment]!['derives_from'],
        'equipment_asset',
      );
      expect(
        assets[TemplateAssets.ictEquipment]!['derives_from'],
        'equipment_asset',
      );
      expect(
        assets[TemplateAssets.vehiclePlant]!['derives_from'],
        'equipment_asset',
      );
      expect(
        assets[TemplateAssets.furnitureFitting]!['derives_from'],
        'equipment_asset',
      );
    },
  );

  test('meeting ships its five child-row shapes', () {
    expect(
      _keysIn(assets[TemplateAssets.meeting]!['child_rows'], 'row_key'),
      <String>['agenda_item', 'attendee', 'apology', 'decision', 'action_item'],
    );
  });
}

Map<String, Object?> _asObject(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is String) {
    final Object? decoded = jsonDecode(value);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return <String, Object?>{
        for (final MapEntry<dynamic, dynamic> entry in decoded.entries)
          entry.key.toString(): entry.value,
      };
    }
  }
  if (value is Map) {
    return <String, Object?>{
      for (final MapEntry<dynamic, dynamic> entry in value.entries)
        entry.key.toString(): entry.value,
    };
  }
  return <String, Object?>{};
}

String _asString(Object? value) => value is String ? value : '';

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return <String>[
    for (final Object? item in value)
      if (item is String) item,
  ];
}

List<String> _keysIn(Object? raw, String key) {
  if (raw is! List) {
    return const <String>[];
  }
  return <String>[
    for (final Object? item in raw) _asString(_asObject(item)[key]),
  ];
}

Set<String> _enumAt(Map<String, Object?> root, List<String> path) {
  Object? cursor = root;
  for (final String key in path) {
    cursor = _asObject(cursor)[key];
  }
  return _stringList(cursor).toSet();
}

Map<String, Set<String>> _groupKeys(String source) {
  final Map<String, Object?> root = _asObject(source);
  return <String, Set<String>>{
    for (final MapEntry<String, Object?> entry in root.entries)
      entry.key: _fieldKeys(_asObject(entry.value)),
  };
}

List<Map<String, Object?>> _fields(Map<String, Object?> owner) {
  final Object? raw = owner['fields'];
  if (raw is! List) {
    return const <Map<String, Object?>>[];
  }
  return <Map<String, Object?>>[
    for (final Object? item in raw) _asObject(item),
  ];
}

Set<String> _fieldKeys(Map<String, Object?> owner) {
  return <String>{
    for (final Map<String, Object?> field in _fields(owner))
      if (_asString(field['field_key']).isNotEmpty)
        _asString(field['field_key']),
  };
}

Set<String> _inheritedKeys(
  Map<String, Object?> asset,
  Map<String, Set<String>> groups,
  Map<String, Map<String, Object?>> byKey,
) {
  final Set<String> keys = <String>{};
  for (final String group in _stringList(asset['inherits_groups'])) {
    keys.addAll(groups[group] ?? const <String>{});
  }
  String? parent = _asString(asset['derives_from']);
  if (parent.isEmpty) {
    parent = null;
  }
  final Set<String> seen = <String>{};
  while (parent != null && seen.add(parent)) {
    final Map<String, Object?>? next = byKey[parent];
    if (next == null) {
      break;
    }
    keys.addAll(_fieldKeys(next));
    for (final String group in _stringList(next['inherits_groups'])) {
      keys.addAll(groups[group] ?? const <String>{});
    }
    final String nextParent = _asString(next['derives_from']);
    parent = nextParent.isEmpty ? null : nextParent;
  }
  return keys;
}

void _expectSchema(
  String path,
  Map<String, Object?> asset,
  List<String> requiredAssetKeys,
  List<String> requiredFieldKeys,
  Set<String> allowedTypes,
) {
  for (final String key in requiredAssetKeys) {
    expect(asset.containsKey(key), isTrue, reason: '$path is missing "$key"');
  }
  expect(asset['schema_version'], 1, reason: path);
  expect(
    _asString(asset['template_key']),
    matches(RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$')),
  );
  expect(_asString(asset['name']), startsWith('templates.'));
  expect(asset['identity_fields'], isA<List<dynamic>>());
  expect(asset['inherits_groups'], isA<List<dynamic>>());
  expect(asset['fields'], isA<List<dynamic>>());
  expect(asset['child_rows'], isA<List<dynamic>>());

  for (final Map<String, Object?> field in _fields(asset)) {
    for (final String key in requiredFieldKeys) {
      expect(
        field.containsKey(key),
        isTrue,
        reason: '$path field ${field['field_key']} is missing "$key"',
      );
    }
    expect(allowedTypes, contains(field['type']), reason: path);
    expect(
      const <String>{'REQUIRED', 'RECOMMENDED', 'OPTIONAL'},
      contains(field['required']),
      reason: path,
    );
    expect(_asString(field['label']), startsWith('templates.'));
  }
}
