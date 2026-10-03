import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'field_def.dart';
import 'template_def.dart';
import 'template_json.dart';

/// Consecutive template diffs, stored snapshots, and record migration (§18).
///
/// Version numbers still bump in the template repository save. This type
/// records what changed and moves records only after the operator confirms.
final class TemplateVersioning {
  /// Creates a preview of what moving [behindCount] records will do.
  const TemplateVersioning({
    required this.added,
    required this.removed,
    required this.retyped,
    required this.behindCount,
    this.unresolved = 0,
    this.retiring = const <({String fieldKey, String label, int records})>[],
  });

  /// The preview when there is no template to compare against: nothing
  /// moves.
  const TemplateVersioning.none()
    : added = const <({String fieldKey, String label, int records})>[],
      removed = const <({String fieldKey, String label, int records})>[],
      retyped = const <({String fieldKey, String label, int records})>[],
      behindCount = 0,
      unresolved = 0,
      retiring = const <({String fieldKey, String label, int records})>[];

  /// Fields on the current template that older records do not have.
  final List<({String fieldKey, String label, int records})> added;

  /// Fields older records have that the current template dropped.
  final List<({String fieldKey, String label, int records})> removed;

  /// Fields whose type changed between the captured shape and now.
  final List<({String fieldKey, String label, int records})> retyped;

  /// Records still on an earlier captured version.
  final int behindCount;

  /// Behind records whose captured version this device no longer knows, so
  /// their added, removed and retyped fields cannot be listed.
  final int unresolved;

  /// Stored values of the [unresolved] records that a move retires because
  /// the current template has no such field, with how many records hold
  /// each. The operator sees them before anything moves.
  final List<({String fieldKey, String label, int records})> retiring;

  /// Whether any record would move.
  bool get isEmpty => behindCount == 0;

  /// Added, removed and retyped field keys between [from] and [to].
  static ({List<String> added, List<String> removed, List<String> retyped})
  diff(TemplateDef from, TemplateDef to) {
    final Map<String, FieldDef> before = <String, FieldDef>{
      for (final FieldDef field in from.fields) field.fieldKey: field,
    };
    final Map<String, FieldDef> after = <String, FieldDef>{
      for (final FieldDef field in to.fields) field.fieldKey: field,
    };
    return (
      added: <String>[
        for (final FieldDef field in to.fields)
          if (!before.containsKey(field.fieldKey)) field.fieldKey,
      ],
      removed: <String>[
        for (final FieldDef field in from.fields)
          if (!after.containsKey(field.fieldKey)) field.fieldKey,
      ],
      retyped: <String>[
        for (final FieldDef field in to.fields)
          if (before[field.fieldKey] != null &&
              before[field.fieldKey]!.type != field.type)
            field.fieldKey,
      ],
    );
  }

  /// Whether [to] is a structural edit of [from] (§18).
  static bool isStructural(TemplateDef from, TemplateDef to) {
    final ({List<String> added, List<String> removed, List<String> retyped})
    change = diff(from, to);
    if (change.added.isNotEmpty ||
        change.removed.isNotEmpty ||
        change.retyped.isNotEmpty) {
      return true;
    }
    if (from.fields.length != to.fields.length) {
      return true;
    }
    for (int index = 0; index < from.fields.length; index++) {
      final FieldDef before = from.fields[index];
      final FieldDef after = to.fields[index];
      if (before != after) {
        return true;
      }
    }
    return from.identityFieldKeys.join('\u0000') !=
        to.identityFieldKeys.join('\u0000');
  }

  /// Stores [from] on [to] so records captured under it can still resolve it.
  static TemplateDef remember({
    required TemplateDef from,
    required TemplateDef to,
  }) {
    // Every persisted edit receives a version, including a name-only edit.
    // Remember each predecessor so a captured version always resolves.
    final Map<int, TemplateDef> history = <int, TemplateDef>{
      ..._historyOf(to),
      ..._historyOf(from),
    };
    history.putIfAbsent(from.version, () => from);
    return to.copyWith(detection: _writeHistory(to.detection, history));
  }

  /// The field list as it was at [capturedVersion], or null when unknown.
  static TemplateDef? shapeFor(TemplateDef current, int capturedVersion) {
    if (capturedVersion <= 0) {
      return null;
    }
    if (capturedVersion == current.version) {
      return current;
    }
    return _historyOf(current)[capturedVersion];
  }

  /// Decodes stored shapes once for a batch of captured records.
  static Map<int, TemplateDef> shapesOf(TemplateDef current) =>
      Map<int, TemplateDef>.unmodifiable(<int, TemplateDef>{
        ..._historyOf(current),
        current.version: current,
      });

  /// Latest known definitions, including retired keys and their visibility.
  static Map<String, FieldDef> latestFields(Iterable<TemplateDef> shapes) {
    final Map<String, (int, FieldDef)> latest = <String, (int, FieldDef)>{};
    for (final TemplateDef shape in shapes) {
      for (final FieldDef field in shape.fields) {
        if (shape.version >= (latest[field.fieldKey]?.$1 ?? -1)) {
          latest[field.fieldKey] = (shape.version, field);
        }
      }
    }
    return <String, FieldDef>{
      for (final entry in latest.entries) entry.key: entry.value.$2,
    };
  }

  /// Preview of added, removed and retyped fields for records still behind.
  factory TemplateVersioning.preview({
    required TemplateDef current,
    required List<CapturedTemplateRecord> records,
  }) {
    final List<CapturedTemplateRecord> behind = <CapturedTemplateRecord>[
      for (final CapturedTemplateRecord record in records)
        if (record.templateVersion < current.version) record,
    ];
    final Map<String, ({String label, int records})> added =
        <String, ({String label, int records})>{};
    final Map<String, ({String label, int records})> removed =
        <String, ({String label, int records})>{};
    final Map<String, ({String label, int records})> retyped =
        <String, ({String label, int records})>{};
    final Map<String, ({String label, int records})> retiring =
        <String, ({String label, int records})>{};
    final Set<String> active = <String>{
      for (final FieldDef field in current.fields) field.fieldKey,
    };
    final Map<int, TemplateDef> shapes = shapesOf(current);
    int unresolved = 0;
    for (final CapturedTemplateRecord record in behind) {
      final TemplateDef? old = shapes[record.templateVersion];
      if (old == null) {
        // The captured shape is gone, so name what the move would retire:
        // every stored value the current template has no field for.
        unresolved++;
        _tally(retiring, <String>[
          for (final String key in record.fields.keys)
            if (!active.contains(key) && !record.retired.contains(key)) key,
        ], current);
        continue;
      }
      final ({List<String> added, List<String> removed, List<String> retyped})
      change = diff(old, current);
      _tally(added, change.added, current);
      _tally(removed, change.removed, old);
      _tally(retyped, change.retyped, current);
    }
    return TemplateVersioning(
      added: _rows(added),
      removed: _rows(removed),
      retyped: _rows(retyped),
      behindCount: behind.length,
      unresolved: unresolved,
      retiring: _rows(retiring),
    );
  }

  /// Moves every behind record onto [current.version] in one replacement list.
  ///
  /// Removed-field values stay on the record and are marked retired. A caller
  /// that fails while persisting [next] must not keep a partial write.
  static List<CapturedTemplateRecord> migrate({
    required TemplateDef current,
    required List<CapturedTemplateRecord> records,
  }) {
    return <CapturedTemplateRecord>[
      for (final CapturedTemplateRecord record in records)
        record.templateVersion >= current.version
            ? record
            : _move(record, current),
    ];
  }

  /// Persists [migrate] as one result so a failure leaves every record behind.
  static Future<Result<List<CapturedTemplateRecord>>> apply({
    required TemplateDef current,
    required List<CapturedTemplateRecord> records,
    required Future<Result<void>> Function(List<CapturedTemplateRecord> next)
    persist,
  }) async {
    final List<CapturedTemplateRecord> next = migrate(
      current: current,
      records: records,
    );
    final Result<void> written = await persist(next);
    return switch (written) {
      Success<void>() => Success<List<CapturedTemplateRecord>>(next),
      FailureResult<void>(:final Failure failure) =>
        FailureResult<List<CapturedTemplateRecord>>(failure),
    };
  }
}

/// One captured record as versioning sees it. Values stay when a field leaves.
typedef CapturedTemplateRecord = ({
  String id,
  int templateVersion,
  Map<String, String> fields,
  Set<String> retired,
});

const String _versionsKey = '_tapture_versions';

/// [record] on [current]'s version. The one retirement rule, which the
/// durable move applies too: every stored value the current template has
/// no field for is retired, and one it defines again is live again.
CapturedTemplateRecord _move(
  CapturedTemplateRecord record,
  TemplateDef current,
) {
  final Set<String> active = <String>{
    for (final FieldDef field in current.fields) field.fieldKey,
  };
  return (
    id: record.id,
    templateVersion: current.version,
    fields: Map<String, String>.of(record.fields),
    retired: <String>{
      for (final String key in <String>{
        ...record.fields.keys,
        ...record.retired,
      })
        if (!active.contains(key)) key,
    },
  );
}

void _tally(
  Map<String, ({String label, int records})> into,
  List<String> keys,
  TemplateDef source,
) {
  final Map<String, FieldDef> fields = <String, FieldDef>{
    for (final FieldDef field in source.fields) field.fieldKey: field,
  };
  for (final String key in keys) {
    final ({String label, int records})? existing = into[key];
    into[key] = (
      label: fields[key]?.label ?? key,
      records: (existing?.records ?? 0) + 1,
    );
  }
}

List<({String fieldKey, String label, int records})> _rows(
  Map<String, ({String label, int records})> source,
) {
  return <({String fieldKey, String label, int records})>[
    for (final MapEntry<String, ({String label, int records})> entry
        in source.entries)
      (
        fieldKey: entry.key,
        label: entry.value.label,
        records: entry.value.records,
      ),
  ];
}

Map<int, TemplateDef> _historyOf(TemplateDef template) {
  final Object? raw = template.detection[_versionsKey];
  if (raw is! Map) {
    return <int, TemplateDef>{};
  }
  final Map<int, TemplateDef> history = <int, TemplateDef>{};
  raw.forEach((Object? key, Object? value) {
    final int? version = int.tryParse('$key');
    if (version == null || value is! Map) {
      return;
    }
    history[version] = _shapeFrom(template, version, value);
  });
  return history;
}

Map<String, Object?> _writeHistory(
  Map<String, Object?> detection,
  Map<int, TemplateDef> history,
) {
  final Map<String, Object?> next = Map<String, Object?>.of(detection);
  next[_versionsKey] = <String, Object?>{
    for (final MapEntry<int, TemplateDef> entry in history.entries)
      '${entry.key}': <String, Object?>{...TemplateJson.encode(entry.value)},
  };
  return next;
}

TemplateDef _shapeFrom(
  TemplateDef current,
  int version,
  Map<Object?, Object?> raw,
) {
  if (raw.containsKey('schema_version')) {
    final Result<TemplateDef> decoded = TemplateJson.decode(
      raw,
      projectId: current.projectId ?? '',
    );
    if (decoded case Success<TemplateDef>(:final TemplateDef value)) {
      return value.copyWith(
        id: current.id,
        version: version,
        projectId: current.projectId,
        source: current.source,
      );
    }
  }
  // Read the compact snapshots written before task 009's durable migration.
  final Object? fields = raw['fields'];
  return current.copyWith(
    version: version,
    fields: fields is List
        ? <FieldDef>[
            for (final Object? item in fields)
              if (item is Map) _fieldFrom(item),
          ]
        : const <FieldDef>[],
  );
}

FieldDef _fieldFrom(Map<Object?, Object?> raw) {
  return FieldDef(
    fieldKey: '${raw['fieldKey'] ?? ''}',
    label: '${raw['label'] ?? ''}',
    type: _typeOf(raw['type']),
    requiredness: _requirednessOf(raw['requiredness']),
    hidden: raw['hidden'] == true,
    outputColumn: raw['outputColumn'] is String
        ? raw['outputColumn'] as String
        : null,
  );
}

FieldType _typeOf(Object? raw) {
  for (final FieldType type in FieldType.values) {
    if (type.name == raw) {
      return type;
    }
  }
  return FieldType.text;
}

Requiredness _requirednessOf(Object? raw) {
  for (final Requiredness value in Requiredness.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return Requiredness.optional;
}
