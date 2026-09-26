import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/template_assets.dart';

void main() {
  late Map<String, Object?> schema;
  late Map<String, Object?> index;
  late Map<String, Set<String>> groupKeys;
  late Map<String, Map<String, Object?>> assets;

  setUpAll(() {
    schema = _asObject(File(TemplateAssets.schema).readAsStringSync());
    index = _asObject(File(TemplateAssets.catalogueIndex).readAsStringSync());
    groupKeys = <String, Set<String>>{
      ..._groupKeys(File(TemplateAssets.groups).readAsStringSync()),
      ..._groupKeys(File(TemplateAssets.catalogueGroups).readAsStringSync()),
    };
    assets = <String, Map<String, Object?>>{
      for (final Map<String, Object?> category in _objects(index['categories']))
        for (final Map<String, Object?> asset in _objects(
          _asObject(
            File(_asString(category['asset'])).readAsStringSync(),
          )['templates'],
        ))
          _asString(asset['template_key']): asset,
    };
  });

  test('the index lists every category asset and its templates', () {
    final List<Map<String, Object?>> categories = _objects(index['categories']);
    expect(categories, hasLength(72));
    expect(_objects(index['supergroups']), hasLength(17));
    expect(_objects(index['packs']), hasLength(26));
    expect(index['template_count'], 2349);
    expect(assets, hasLength(2349));
    int listed = 0;
    for (final Map<String, Object?> category in categories) {
      final String path = _asString(category['asset']);
      expect(path, startsWith('assets/templates/'));
      expect(File(path).existsSync(), isTrue, reason: path);
      listed += category['template_count']! as int;
    }
    expect(listed, 2349);
  });

  test('only the schema, the index, the groups and category files ship', () {
    final List<String> names = <String>[
      for (final FileSystemEntity entity in Directory(
        'assets/templates',
      ).listSync())
        entity.uri.pathSegments.last,
    ]..sort();
    expect(names.where((String name) => name.startsWith('_')), <String>[
      '_catalogue.json',
      '_catalogue_groups.json',
      '_groups.json',
      '_schema.json',
    ]);
    expect(
      names.where((String name) => !name.startsWith('_')),
      everyElement(matches(RegExp(r'^\d{2}_[a-z]+_[a-z0-9_]+\.json$'))),
    );
  });

  test('every template validates against the schema, and resolves '
      'inherited groups and identity keys', () {
    expect(groupKeys.keys.take(4), <String>[
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

    for (final MapEntry<String, Map<String, Object?>> entry in assets.entries) {
      final Map<String, Object?> asset = entry.value;
      _expectSchema(
        entry.key,
        asset,
        requiredAssetKeys,
        requiredFieldKeys,
        allowedTypes,
      );
      for (final String group in _stringList(asset['inherits_groups'])) {
        expect(
          groupKeys.containsKey(group),
          isTrue,
          reason: '${entry.key} inherits the unknown group "$group"',
        );
      }

      final Set<String> inherited = _inheritedKeys(asset, groupKeys, assets);
      final Set<String> own = _fieldKeys(asset);
      expect(
        own.intersection(inherited),
        isEmpty,
        reason: '${entry.key} repeats an inherited field',
      );

      final List<String> identity = _stringList(asset['identity_fields']);
      expect(identity, isNotEmpty, reason: entry.key);
      for (final String key in identity) {
        expect(
          own.contains(key) || inherited.contains(key),
          isTrue,
          reason:
              '${entry.key} identity_fields names "$key", '
              'which groups and the asset do not resolve',
        );
      }
    }
  });
}

List<Map<String, Object?>> _objects(Object? raw) {
  if (raw is! List) {
    return const <Map<String, Object?>>[];
  }
  return <Map<String, Object?>>[
    for (final Object? item in raw) _asObject(item),
  ];
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
