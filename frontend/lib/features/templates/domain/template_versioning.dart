import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'field_def.dart';
import 'template_def.dart';

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
  });

  /// Fields on the current template that older records do not have.
  final List<({String fieldKey, String label, int records})> added;

  /// Fields older records have that the current template dropped.
  final List<({String fieldKey, String label, int records})> removed;

  /// Fields whose type changed between the captured shape and now.
  final List<({String fieldKey, String label, int records})> retyped;

  /// Records still on an earlier captured version.
  final int behindCount;

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
      if (before.fieldKey != after.fieldKey ||
          before.label != after.label ||
          before.hidden != after.hidden ||
          before.requiredness != after.requiredness) {
        return true;
      }
    }
    return false;
  }

  /// Stores [from] on [to] so records captured under it can still resolve it.
  static TemplateDef remember({
    required TemplateDef from,
    required TemplateDef to,
  }) {
    if (!isStructural(from, to)) {
      return to;
    }
    final Map<int, TemplateDef> history = _historyOf(from);
    history.putIfAbsent(from.version, () => from);
    return to.copyWith(detection: _writeHistory(to.detection, history));
  }

  /// The field list as it was at [capturedVersion], or null when unknown.
  static TemplateDef? shapeFor(TemplateDef current, int capturedVersion) {
    if (capturedVersion == current.version) {
      return current;
    }
    return _historyOf(current)[capturedVersion];
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
    for (final CapturedTemplateRecord record in behind) {
      final TemplateDef? old = shapeFor(current, record.templateVersion);
      if (old == null) {
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

CapturedTemplateRecord _move(
  CapturedTemplateRecord record,
  TemplateDef current,
) {
  final TemplateDef? old = TemplateVersioning.shapeFor(
    current,
    record.templateVersion,
  );
  final Set<String> retired = <String>{...record.retired};
  if (old != null) {
    final ({List<String> added, List<String> removed, List<String> retyped})
    change = TemplateVersioning.diff(old, current);
    retired.addAll(change.removed);
  }
  return (
    id: record.id,
    templateVersion: current.version,
    fields: Map<String, String>.of(record.fields),
    retired: retired,
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
      '${entry.key}': <String, Object?>{
        'fields': <Object>[
          for (final FieldDef field in entry.value.fields)
            <String, Object?>{
              'fieldKey': field.fieldKey,
              'label': field.label,
              'type': field.type.name,
              'requiredness': field.requiredness.name,
              'hidden': field.hidden,
              if (field.outputColumn != null)
                'outputColumn': field.outputColumn,
            },
        ],
      },
  };
  return next;
}

TemplateDef _shapeFrom(
  TemplateDef current,
  int version,
  Map<Object?, Object?> raw,
) {
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
