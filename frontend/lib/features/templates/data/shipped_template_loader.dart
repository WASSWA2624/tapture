import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/template_assets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/shipped_template_entry.dart';
import '../domain/template_repository.dart';
import 'template_repository_impl.dart' show templateRepositoryProvider;

/// Reads the shipped library under `assets/templates/`, validates each
/// template, and copies one into a project as a version-1 [TemplateDef]. The
/// packed JSON is never written.
abstract interface class ShippedTemplateLoader {
  /// Production loader. [readAsset] is for tests that must not open
  /// [rootBundle]; the app reads through generated [TemplateAssets] paths.
  factory ShippedTemplateLoader({
    required TemplateRepository templates,
    Future<String> Function(String path)? readAsset,
  }) = _AssetShippedTemplateLoader;

  /// Every shipped template as a light row, in catalogue order. Fields stay
  /// unresolved until [template] is asked for one.
  Future<Result<List<ShippedTemplateEntry>>> entries();

  /// One shipped template with its groups resolved and labels still
  /// localisation keys.
  Future<Result<TemplateDef>> template(String templateKey);

  /// Writes an editable copy of [templateKey] onto [projectId] at version 1.
  Future<Result<TemplateDef>> copyToProject({
    required String templateKey,
    required String projectId,
    required String name,
  });
}

/// The library store. Defaults to a failing stand-in so suites never open
/// assets (FE-TEST-03). [main] keeps the factory above, which reads the
/// bundle.
final Provider<ShippedTemplateLoader> shippedTemplateLoaderProvider =
    Provider<ShippedTemplateLoader>((Ref ref) {
      return ShippedTemplateLoader(
        templates: ref.watch(templateRepositoryProvider),
      );
    });

final class _AssetShippedTemplateLoader implements ShippedTemplateLoader {
  _AssetShippedTemplateLoader({
    required this._templates,
    Future<String> Function(String path)? readAsset,
  }) : _read = readAsset ?? rootBundle.loadString;

  final TemplateRepository _templates;
  final Future<String> Function(String path) _read;

  /// The catalogue index, built once off the UI thread and kept (FE-PERF-02).
  Future<_Catalogue>? _catalogue;

  /// Every field group, the four of §13.3 and the catalogue's, once read.
  Future<Map<String, _Group>>? _allGroups;

  @override
  Future<Result<List<ShippedTemplateEntry>>> entries() {
    return _guard(() async => (await _catalogueIndex()).entries);
  }

  @override
  Future<Result<TemplateDef>> template(String templateKey) {
    return _guard(() => _resolve(templateKey));
  }

  @override
  Future<Result<TemplateDef>> copyToProject({
    required String templateKey,
    required String projectId,
    required String name,
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const FailureResult<TemplateDef>(
        ValidationFailure(
          message: 'A template needs a name.',
          recoveryAction: 'Enter a name and save again.',
        ),
      );
    }
    if (projectId.isEmpty) {
      return const FailureResult<TemplateDef>(
        ValidationFailure(
          message: Copy.statusNoProject,
          recoveryAction: 'Open a project, then add the template.',
        ),
      );
    }
    final Result<TemplateDef> loaded = await template(templateKey);
    switch (loaded) {
      case FailureResult<TemplateDef>(:final Failure failure):
        return FailureResult<TemplateDef>(failure);
      case Success<TemplateDef>(:final TemplateDef value):
        return _templates.save(_projectCopy(value, projectId, trimmed));
    }
  }

  /// Runs [load], turning what it throws into a typed failure.
  Future<Result<T>> _guard<T>(Future<T> Function() load) async {
    try {
      return Success<T>(await load());
    } on Failure catch (failure) {
      return FailureResult<T>(failure);
    } on FormatException {
      return FailureResult<T>(_corrupt);
    } on Object catch (error) {
      return FailureResult<T>(
        StorageFailure(
          message: 'The shipped templates could not be read.',
          recoveryAction: Failure.from(error).recoveryAction ?? 'Try again.',
        ),
      );
    }
  }

  /// [templateKey] resolved from its category's asset.
  Future<TemplateDef> _resolve(String templateKey) async {
    final _Catalogue catalogue = await _catalogueIndex();
    final String? path = catalogue.assetOf[templateKey];
    final Map<String, Object?>? asset = path == null
        ? null
        : _templateIn(_object(jsonDecode(await _read(path))), templateKey);
    if (asset == null) {
      throw const ValidationFailure(
        message: 'That shipped template is not on this device.',
        recoveryAction: 'Pick another template from the library.',
      );
    }
    final _Schema schema = await _schema();
    _assertAsset(asset, schema);
    return _toDef(
      asset,
      await _groupsWithCatalogue(schema),
      <String, Map<String, Object?>>{templateKey: asset},
      schema,
    );
  }

  /// The catalogue index, read once. A failed read is not kept, so the next
  /// call tries again.
  Future<_Catalogue> _catalogueIndex() async {
    final Future<_Catalogue> pending = _catalogue ??= _loadCatalogue();
    try {
      return await pending;
    } on Object {
      _catalogue = null;
      rethrow;
    }
  }

  Future<_Catalogue> _loadCatalogue() async {
    final String index = await _read(TemplateAssets.catalogueIndex);
    final List<String> paths = <String>[
      for (final Map<String, Object?> category in _objects(
        _object(jsonDecode(index))['categories'],
      ))
        _string(category['asset']),
    ];
    final List<String> files = await Future.wait(<Future<String>>[
      for (final String path in paths) _read(path),
    ]);
    final Result<_Catalogue> built =
        await runIsolate<_CatalogueSource, _Catalogue>(_indexCatalogue, (
          index: index,
          groups: <String>[
            await _read(TemplateAssets.groups),
            await _read(TemplateAssets.catalogueGroups),
          ],
          paths: paths,
          files: files,
        ));
    return switch (built) {
      Success<_Catalogue>(:final _Catalogue value) => value,
      FailureResult<_Catalogue>(:final Failure failure) => throw Failure.from(
        failure,
      ),
    };
  }

  /// The four groups of §13.3 and the catalogue's, read once.
  Future<Map<String, _Group>> _groupsWithCatalogue(_Schema schema) async {
    final Future<Map<String, _Group>> pending = _allGroups ??= () async {
      return <String, _Group>{
        ...await _groups(schema),
        ...await _groupsAt(TemplateAssets.catalogueGroups, schema),
      };
    }();
    try {
      return await pending;
    } on Object {
      _allGroups = null;
      rethrow;
    }
  }

  Future<_Schema> _schema() async {
    final Map<String, Object?> root = _object(
      jsonDecode(await _read(TemplateAssets.schema)),
    );
    final Map<String, Object?> field = _object(
      _object(root[r'$defs'])['field'],
    );
    return (
      assetKeys: _strings(root['required']),
      fieldKeys: _strings(field['required']),
      types: _strings(_object(_object(field['properties'])['type'])['enum']),
    );
  }

  Future<Map<String, _Group>> _groups(_Schema schema) {
    return _groupsAt(TemplateAssets.groups, schema);
  }

  Future<Map<String, _Group>> _groupsAt(String path, _Schema schema) async {
    final Map<String, Object?> root = _object(jsonDecode(await _read(path)));
    if (root.isEmpty) {
      throw const CorruptionFailure(
        message: 'The inherited field groups could not be read.',
      );
    }
    return <String, _Group>{
      for (final MapEntry<String, Object?> entry in root.entries)
        entry.key: _groupOf(_object(entry.value), schema),
    };
  }

  _Group _groupOf(Map<String, Object?> raw, _Schema schema) {
    final InputMode mode = _modeOf(_string(raw['input_mode'])) ?? InputMode.any;
    return (
      mode: mode,
      fields: <FieldDef>[
        for (final Map<String, Object?> field in _objects(raw['fields']))
          _fieldOf(field, schema, mode),
      ],
    );
  }

  void _assertAsset(Map<String, Object?> asset, _Schema schema) {
    for (final String key in schema.assetKeys) {
      if (!asset.containsKey(key)) {
        throw ValidationFailure(
          message: 'A shipped template is missing "$key".',
          recoveryAction: 'Reinstall the app, then try again.',
        );
      }
    }
    if (asset['schema_version'] != 1) {
      throw const ValidationFailure(
        message: 'A shipped template uses an unknown schema.',
        recoveryAction: 'Update the app, then try again.',
      );
    }
    if (!_snake.hasMatch(_string(asset['template_key']))) {
      throw const ValidationFailure(
        message: 'A shipped template has an invalid key.',
        recoveryAction: 'Reinstall the app, then try again.',
      );
    }
    if (!_string(asset['name']).startsWith(_keyPrefix)) {
      throw const ValidationFailure(
        message: 'A shipped template name is not a localisation key.',
        recoveryAction: 'Reinstall the app, then try again.',
      );
    }
  }

  TemplateDef _toDef(
    Map<String, Object?> asset,
    Map<String, _Group> groups,
    Map<String, Map<String, Object?>> byKey,
    _Schema schema,
  ) {
    final List<FieldDef> fields = _resolveFields(asset, groups, byKey, schema);
    final Set<String> keys = <String>{
      for (final FieldDef field in fields) field.fieldKey,
    };
    final List<String> identity = _strings(asset['identity_fields']);
    for (final String key in identity) {
      if (!keys.contains(key)) {
        throw const ValidationFailure(
          message: 'A shipped template names an unknown identity field.',
          recoveryAction: 'Reinstall the app, then try again.',
        );
      }
    }
    return TemplateDef(
      id: '',
      templateKey: _string(asset['template_key']),
      name: _string(asset['name']),
      version: 1,
      fields: <FieldDef>[
        for (final FieldDef field in fields)
          field.copyWith(identity: identity.contains(field.fieldKey)),
      ],
      identityFieldKeys: identity,
      rows: _rowsOf(asset),
      kind: _string(asset['kind']),
      source: _shippedSource,
    );
  }

  List<FieldDef> _resolveFields(
    Map<String, Object?> asset,
    Map<String, _Group> groups,
    Map<String, Map<String, Object?>> byKey,
    _Schema schema,
  ) {
    final List<FieldDef> fields = <FieldDef>[];
    final Set<String> seen = <String>{};
    void addAll(Iterable<FieldDef> next) {
      for (final FieldDef field in next) {
        if (seen.add(field.fieldKey)) {
          fields.add(field.copyWith(sortOrder: fields.length));
        }
      }
    }

    final String parentKey = _string(asset['derives_from']);
    if (parentKey.isNotEmpty) {
      final Map<String, Object?>? parent = byKey[parentKey];
      if (parent == null) {
        throw const ValidationFailure(
          message: 'A shipped template names an unknown parent.',
          recoveryAction: 'Reinstall the app, then try again.',
        );
      }
      addAll(_resolveFields(parent, groups, byKey, schema));
    }
    for (final String name in _strings(asset['inherits_groups'])) {
      final _Group? group = groups[name];
      if (group == null) {
        throw const ValidationFailure(
          message: 'A shipped template names an unknown field group.',
          recoveryAction: 'Reinstall the app, then try again.',
        );
      }
      addAll(group.fields);
    }
    addAll(<FieldDef>[
      for (final Map<String, Object?> field in _objects(asset['fields']))
        _fieldOf(field, schema, InputMode.any),
    ]);
    return fields;
  }

  FieldDef _fieldOf(
    Map<String, Object?> raw,
    _Schema schema,
    InputMode fallback,
  ) {
    for (final String key in schema.fieldKeys) {
      if (!raw.containsKey(key)) {
        throw ValidationFailure(
          message: 'A shipped field is missing "$key".',
          recoveryAction: 'Reinstall the app, then try again.',
        );
      }
    }
    final String typeName = _string(raw['type']);
    if (!schema.types.contains(typeName)) {
      throw const ValidationFailure(
        message: 'A shipped field uses an unknown type.',
        recoveryAction: 'Reinstall the app, then try again.',
      );
    }
    final FieldType? type = _typeOf(typeName);
    if (type == null) {
      throw const ValidationFailure(
        message: 'A shipped field uses an unknown type.',
        recoveryAction: 'Reinstall the app, then try again.',
      );
    }
    final String label = _string(raw['label']);
    if (!label.startsWith(_keyPrefix)) {
      throw const ValidationFailure(
        message: 'A shipped field label is not a localisation key.',
        recoveryAction: 'Reinstall the app, then try again.',
      );
    }
    return FieldDef(
      fieldKey: _string(raw['field_key']),
      label: label,
      type: type,
      requiredness: _requirednessOf(_string(raw['required'])),
      unit: _optional(raw['unit']),
      helpText: _optional(raw['help']),
      inputMode: _modeOf(_string(raw['input_mode'])) ?? fallback,
      options: _optionsOf(raw['options']),
      group: _optional(raw['group']),
      requiredWhen: _optional(raw['required_when']),
      stickable: raw['stickable'] == true,
      refine: raw['refine'] == true,
      autoFill: _autoFillOf(_string(raw['auto_fill'])),
      identity: false,
    );
  }

  List<TemplateRow> _rowsOf(Map<String, Object?> asset) {
    final List<Map<String, Object?>> raw = _objects(asset['child_rows']);
    return <TemplateRow>[
      for (int index = 0; index < raw.length; index++)
        TemplateRow(
          identifier: _string(raw[index]['row_key']),
          label: _string(raw[index]['label']),
          outputRowNumber: index + 1,
          metadata: <String, Object?>{
            if (raw[index]['fields'] != null) 'fields': raw[index]['fields'],
          },
        ),
    ];
  }
}

TemplateDef _projectCopy(TemplateDef source, String projectId, String name) {
  return TemplateDef(
    id: '',
    templateKey: source.templateKey,
    name: name,
    version: 1,
    fields: <FieldDef>[
      for (final FieldDef field in source.fields)
        field.copyWith(
          label: Copy.shippedLabel(field.label),
          helpText: field.helpText == null
              ? null
              : Copy.shippedLabel(field.helpText!),
          options: <Object>[
            for (final Object option in field.options) _resolveOption(option),
          ],
        ),
    ],
    identityFieldKeys: List<String>.of(source.identityFieldKeys),
    rows: <TemplateRow>[
      for (final TemplateRow row in source.rows)
        row.copyWith(
          label: Copy.shippedLabel(row.label),
          aliases: List<String>.of(row.aliases),
          metadata: Map<String, Object?>.of(row.metadata),
        ),
    ],
    projectId: projectId,
    kind: source.kind,
    source: _shippedSource,
    detection: Map<String, Object?>.of(source.detection),
  );
}

Object _resolveOption(Object option) {
  if (option is String) {
    return Copy.shippedLabel(option);
  }
  if (option is Map) {
    final Map<String, Object?> map = <String, Object?>{
      for (final MapEntry<dynamic, dynamic> entry in option.entries)
        entry.key.toString(): entry.value,
    };
    final String? label = map['label'] as String?;
    if (label != null) {
      map['label'] = Copy.shippedLabel(label);
    }
    return map;
  }
  return option;
}

FieldType? _typeOf(String raw) {
  return switch (raw) {
    'text' => FieldType.text,
    'long_text' => FieldType.longText,
    'number' => FieldType.number,
    'decimal' => FieldType.decimal,
    'currency' => FieldType.currency,
    'percentage' => FieldType.percentage,
    'date' => FieldType.date,
    'time' => FieldType.time,
    'date_time' => FieldType.dateTime,
    'boolean' => FieldType.boolean,
    'choice' => FieldType.choice,
    'multi_choice' => FieldType.multiChoice,
    'lookup' => FieldType.lookup,
    'barcode' => FieldType.barcode,
    'photo_reference' => FieldType.photoReference,
    'document_reference' => FieldType.documentReference,
    'gps_location' => FieldType.gpsLocation,
    'signature' => FieldType.signature,
    'computed' => FieldType.computed,
    _ => null,
  };
}

Requiredness _requirednessOf(String raw) {
  return switch (raw) {
    'REQUIRED' => Requiredness.required,
    'RECOMMENDED' => Requiredness.recommended,
    _ => Requiredness.optional,
  };
}

AutoFill? _autoFillOf(String raw) {
  return switch (raw) {
    'now' => AutoFill.now,
    'today' => AutoFill.today,
    'time' => AutoFill.time,
    'sequence' => AutoFill.sequence,
    'operator' => AutoFill.operator,
    'device' => AutoFill.device,
    'gps' => AutoFill.gps,
    'context' => AutoFill.context,
    _ => null,
  };
}

InputMode? _modeOf(String raw) {
  return switch (raw) {
    'any' => InputMode.any,
    'manual_only' => InputMode.manualOnly,
    'ai_allowed' => InputMode.aiAllowed,
    'auto' => InputMode.auto,
    _ => null,
  };
}

Map<String, Object?> _object(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return <String, Object?>{
      for (final MapEntry<dynamic, dynamic> entry in value.entries)
        entry.key.toString(): entry.value,
    };
  }
  throw const CorruptionFailure();
}

List<Map<String, Object?>> _objects(Object? value) {
  if (value is! List) {
    return const <Map<String, Object?>>[];
  }
  return <Map<String, Object?>>[
    for (final Object? item in value) _object(item),
  ];
}

List<String> _strings(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return <String>[
    for (final Object? item in value)
      if (item is String) item,
  ];
}

List<Object> _optionsOf(Object? value) {
  if (value is! List) {
    return const <Object>[];
  }
  return <Object>[
    for (final Object? item in value)
      if (item is String) item else if (item != null) _object(item),
  ];
}

String _string(Object? value) => value is String ? value : '';

String? _optional(Object? value) {
  final String text = _string(value);
  return text.isEmpty ? null : text;
}

typedef _Schema = ({
  List<String> assetKeys,
  List<String> fieldKeys,
  List<String> types,
});

typedef _Group = ({InputMode mode, List<FieldDef> fields});

/// The template keyed [templateKey] in one catalogue category asset.
Map<String, Object?>? _templateIn(
  Map<String, Object?> category,
  String templateKey,
) {
  for (final Map<String, Object?> candidate in _objects(
    category['templates'],
  )) {
    if (candidate['template_key'] == templateKey) {
      return candidate;
    }
  }
  return null;
}

/// What the isolate indexes: the index, the group files, and each category
/// asset beside its path.
typedef _CatalogueSource = ({
  String index,
  List<String> groups,
  List<String> paths,
  List<String> files,
});

/// The catalogue as the library lists it, and where each template lives.
typedef _Catalogue = ({
  List<ShippedTemplateEntry> entries,
  Map<String, String> assetOf,
});

/// Builds the catalogue index off the UI thread (FE-PERF-02). Counts each
/// template's resolved fields from group keys, without building a field.
_Catalogue _indexCatalogue(_CatalogueSource source) {
  final Map<String, Object?> index = _object(jsonDecode(source.index));
  final Map<String, Set<String>> groupKeys = <String, Set<String>>{
    for (final String text in source.groups)
      for (final MapEntry<String, Object?> group in _object(
        jsonDecode(text),
      ).entries)
        group.key: <String>{
          for (final Map<String, Object?> field in _objects(
            _object(group.value)['fields'],
          ))
            _string(field['field_key']),
        },
  };
  final Map<String, ShippedRecordType> types = <String, ShippedRecordType>{
    for (final Map<String, Object?> pack in _objects(index['packs']))
      _string(pack['code']): ShippedRecordType(
        code: _string(pack['code']),
        title: _string(pack['title']),
        kind: _string(pack['kind']),
        capture: _string(pack['capture']),
        aiAssistance: _string(pack['ai_assistance']),
        outputs: _string(pack['outputs']),
        review: _string(pack['review']),
      ),
  };
  final Map<String, String> supergroups = <String, String>{
    for (final Map<String, Object?> supergroup in _objects(
      index['supergroups'],
    ))
      _string(supergroup['code']): _string(supergroup['title']),
  };
  final List<Map<String, Object?>> categories = _objects(index['categories']);
  if (categories.length != source.files.length) {
    throw const CorruptionFailure(
      message: 'A shipped template could not be read.',
    );
  }
  final List<ShippedTemplateEntry> entries = <ShippedTemplateEntry>[];
  final Map<String, String> assetOf = <String, String>{};
  for (int at = 0; at < categories.length; at++) {
    final String supergroup = _string(categories[at]['supergroup']);
    final ShippedCatalogueCategory category = ShippedCatalogueCategory(
      code: _string(categories[at]['code']),
      title: _string(categories[at]['title']),
      supergroupCode: supergroup,
      supergroupTitle: supergroups[supergroup] ?? '',
    );
    for (final Map<String, Object?> template in _objects(
      _object(jsonDecode(source.files[at]))['templates'],
    )) {
      final String key = _string(template['template_key']);
      if (!_snake.hasMatch(key) || assetOf.containsKey(key)) {
        throw const ValidationFailure(
          message: 'A shipped template has an invalid key.',
          recoveryAction: 'Reinstall the app, then try again.',
        );
      }
      final List<String> own = <String>[
        for (final Map<String, Object?> field in _objects(template['fields']))
          _string(field['field_key']),
      ];
      final Set<String> resolved = <String>{};
      for (final String group in _strings(template['inherits_groups'])) {
        final Set<String>? keys = groupKeys[group];
        if (keys == null) {
          throw const ValidationFailure(
            message: 'A shipped template names an unknown field group.',
            recoveryAction: 'Reinstall the app, then try again.',
          );
        }
        resolved.addAll(keys);
      }
      resolved.addAll(own);
      entries.add(
        ShippedTemplateEntry(
          templateKey: key,
          kind: _string(template['kind']),
          fieldCount: resolved.length,
          title: _string(template['title']),
          code: _string(template['code']),
          category: category,
          recordType:
              types[_string(template['pack'])] ??
              (throw const ValidationFailure(
                message: 'A shipped template names an unknown record type.',
                recoveryAction: 'Reinstall the app, then try again.',
              )),
          privacy: _string(template['privacy']),
          rollout: _string(template['rollout']),
          fieldKeys: own,
        ),
      );
      assetOf[key] = source.paths[at];
    }
  }
  return (entries: entries, assetOf: assetOf);
}

final RegExp _snake = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

const String _keyPrefix = 'templates.';
const String _shippedSource = 'shipped';

const CorruptionFailure _corrupt = CorruptionFailure(
  message: 'A shipped template could not be read.',
);
