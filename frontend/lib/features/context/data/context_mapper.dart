import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;

import '../domain/context_state.dart';

/// Maps Drift context rows onto domain models and back.
abstract final class ContextMapper {
  /// Assembles a [ContextState] from definition, state and pin rows.
  static ContextState fromRows({
    required List<sqlite.ContextData> definitions,
    required List<sqlite.ContextStateRow> states,
    required Map<String, String> pinned,
  }) {
    final List<ContextLevel> levels = <ContextLevel>[
      for (final sqlite.ContextData row in definitions)
        _levelFromDefinition(row),
    ]..sort((ContextLevel a, ContextLevel b) => a.order.compareTo(b.order));
    final Map<String, String> values = <String, String>{};
    for (final sqlite.ContextStateRow row in states) {
      if (row.level <= 0) {
        continue;
      }
      if (row.fieldKey.isNotEmpty) {
        values[row.fieldKey] = row.value;
        continue;
      }
      for (final ContextLevel level in levels) {
        if (level.order + 1 == row.level &&
            !values.containsKey(level.fieldKey)) {
          values[level.fieldKey] = row.value;
          break;
        }
      }
    }
    return ContextState(levels: levels, values: values, pinned: pinned);
  }

  /// Encodes label + optional datasetId for the definitions table.
  static String encodeLabel(ContextLevel level) {
    if (level.datasetId == null || level.datasetId!.isEmpty) {
      return level.label.isEmpty ? level.fieldKey : level.label;
    }
    return jsonEncode(<String, Object?>{
      'label': level.label.isEmpty ? level.fieldKey : level.label,
      'datasetId': level.datasetId,
    });
  }

  /// Definition companion for one level. Drift [level] is 1-based.
  static sqlite.ContextCompanion definitionToRow({
    required String projectId,
    required ContextLevel level,
  }) {
    return sqlite.ContextCompanion(
      projectId: Value<String>(projectId),
      level: Value<int>(level.order + 1),
      fieldKey: Value<String>(level.fieldKey),
      label: Value<String>(encodeLabel(level)),
    );
  }

  /// Preset from a stored row.
  static ContextPreset presetFromRow(sqlite.ContextPreset row) {
    final ({Map<String, String> values, Map<String, String> pinned}) packed =
        _decodePresetValues(row.values);
    return ContextPreset(
      id: row.id,
      name: row.name,
      values: packed.values,
      pinned: packed.pinned,
      lastUsedAt: row.updatedAt,
    );
  }

  /// JSON for a preset's values column.
  static String encodePresetPayload({
    required Map<String, String> values,
    required Map<String, String> pinned,
  }) {
    return jsonEncode(<String, Object?>{'values': values, 'pinned': pinned});
  }

  /// Reads pins from a level-0 state row, if present.
  static Map<String, String> pinsFromStateRows(
    List<sqlite.ContextStateRow> states,
  ) {
    for (final sqlite.ContextStateRow row in states) {
      if (row.level == 0) {
        return _stringMap(row.value);
      }
    }
    return const <String, String>{};
  }

  static ContextLevel _levelFromDefinition(sqlite.ContextData row) {
    final ({String label, String? datasetId}) packed = _decodeLabel(row.label);
    return ContextLevel(
      fieldKey: row.fieldKey,
      order: row.level - 1,
      label: packed.label.isEmpty ? row.fieldKey : packed.label,
      datasetId: packed.datasetId,
    );
  }

  static ({String label, String? datasetId}) _decodeLabel(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.startsWith('{')) {
      try {
        final Object decoded = jsonDecode(trimmed) as Object;
        if (decoded is Map) {
          return (
            label: '${decoded['label'] ?? ''}',
            datasetId: decoded['datasetId'] as String?,
          );
        }
      } on FormatException {
        // Fall through to plain label.
      }
    }
    return (label: raw, datasetId: null);
  }

  static ({Map<String, String> values, Map<String, String> pinned})
  _decodePresetValues(String raw) {
    try {
      final Object decoded = jsonDecode(raw) as Object;
      if (decoded is Map) {
        if (decoded.containsKey('values') || decoded.containsKey('pinned')) {
          return (
            values: _asStringMap(decoded['values']),
            pinned: _asStringMap(decoded['pinned']),
          );
        }
        return (
          values: _asStringMap(decoded),
          pinned: const <String, String>{},
        );
      }
    } on FormatException {
      // Empty.
    }
    return (values: const <String, String>{}, pinned: const <String, String>{});
  }

  static Map<String, String> _asStringMap(Object? raw) {
    if (raw is! Map) {
      return const <String, String>{};
    }
    return <String, String>{
      for (final MapEntry<Object?, Object?> e in raw.entries)
        if (e.key is String) e.key! as String: '${e.value ?? ''}',
    };
  }

  static Map<String, String> _stringMap(String raw) {
    try {
      return _asStringMap(jsonDecode(raw) as Object);
    } on FormatException {
      return const <String, String>{};
    }
  }
}
