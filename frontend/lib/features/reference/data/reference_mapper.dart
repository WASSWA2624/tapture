import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/reference.dart';

import '../domain/reference_dataset.dart';
import '../domain/reference_row.dart';

/// Maps Drift reference rows onto [ReferenceDataset] / [ReferenceRow] and back.
///
/// Presentation never sees a database type; only
/// [ReferenceRepositoryImpl] and this mapper import both layers.
abstract final class ReferenceMapper {
  /// Reads a stored dataset header.
  static ReferenceDataset datasetFromRow(sqlite.ReferenceDatasetRow row) {
    final ({DatasetSource source, bool duplicatesAllowed, String path}) packed =
        _decodeSourceFile(row.sourceFile);
    return ReferenceDataset(
      id: row.id,
      name: row.name,
      keyColumn: row.keyColumn,
      columns: _stringList(row.columns),
      source: packed.source,
      importedAt: row.importedAt,
      rowCount: row.rowCount,
      duplicatesAllowed: packed.duplicatesAllowed,
      projectId: row.projectId,
      sourceFile: packed.path,
    );
  }

  /// Writes [dataset] as an insertable header.
  static sqlite.ReferenceCompanion datasetToRow(ReferenceDataset dataset) {
    return sqlite.ReferenceCompanion(
      id: dataset.id.isEmpty
          ? const Value<String>.absent()
          : Value<String>(dataset.id),
      name: Value<String>(dataset.name),
      scope: Value<ReferenceScope>(
        dataset.projectId == null || dataset.projectId!.isEmpty
            ? ReferenceScope.global
            : ReferenceScope.project,
      ),
      projectId: Value<String?>(
        dataset.projectId == null || dataset.projectId!.isEmpty
            ? null
            : dataset.projectId,
      ),
      keyColumn: Value<String>(dataset.keyColumn),
      columns: Value<String>(jsonEncode(dataset.columns)),
      sourceFile: Value<String>(
        _encodeSourceFile(
          source: dataset.source,
          duplicatesAllowed: dataset.duplicatesAllowed,
          path: dataset.sourceFile,
        ),
      ),
      importedAt: Value<DateTime>(dataset.importedAt),
      rowCount: Value<int>(dataset.rowCount),
    );
  }

  /// Reads a stored lookup row.
  static ReferenceRow rowFromRow(sqlite.ReferenceLookupRow row) {
    final Map<String, String> values = _stringMap(row.values);
    final bool added = values.remove(_addedKey) == 'true';
    return ReferenceRow(
      id: row.id,
      datasetId: row.datasetId,
      key: row.keyValue,
      values: values,
      addedOnDevice: added,
    );
  }

  /// Writes [row] as an insertable lookup row.
  static sqlite.ReferenceRowsCompanion rowToRow(ReferenceRow row) {
    final Map<String, String> values = Map<String, String>.of(row.values);
    if (row.addedOnDevice) {
      values[_addedKey] = 'true';
    } else {
      values.remove(_addedKey);
    }
    return sqlite.ReferenceRowsCompanion(
      id: row.id.isEmpty ? const Value<String>.absent() : Value<String>(row.id),
      datasetId: Value<String>(row.datasetId),
      keyValue: Value<String>(row.key),
      values: Value<String>(jsonEncode(values)),
    );
  }

  /// Cell map ready for [importReferenceDataset].
  static Map<String, String> valuesForImport(ReferenceRow row) {
    final Map<String, String> values = Map<String, String>.of(row.values);
    if (row.addedOnDevice) {
      values[_addedKey] = 'true';
    }
    return values;
  }
}

const String _addedKey = '__tapture_addedOnDevice';
const String _sourceSep = '\u001e';

String _encodeSourceFile({
  required DatasetSource source,
  required bool duplicatesAllowed,
  required String path,
}) {
  return '${source.name}$_sourceSep${duplicatesAllowed ? '1' : '0'}'
      '$_sourceSep$path';
}

({DatasetSource source, bool duplicatesAllowed, String path}) _decodeSourceFile(
  String raw,
) {
  final List<String> parts = raw.split(_sourceSep);
  if (parts.length >= 3) {
    return (
      source:
          _sourceNamed(parts[0]) ??
          _inferSource(parts.sublist(2).join(_sourceSep)),
      duplicatesAllowed: parts[1] == '1',
      path: parts.sublist(2).join(_sourceSep),
    );
  }
  return (source: _inferSource(raw), duplicatesAllowed: false, path: raw);
}

DatasetSource _inferSource(String path) {
  final String lower = path.toLowerCase();
  if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
    return DatasetSource.xlsx;
  }
  if (lower.endsWith('.json')) {
    return DatasetSource.json;
  }
  if (lower.startsWith('device:') || path.isEmpty) {
    return DatasetSource.device;
  }
  return DatasetSource.csv;
}

DatasetSource? _sourceNamed(String name) {
  for (final DatasetSource source in DatasetSource.values) {
    if (source.name == name) {
      return source;
    }
  }
  return null;
}

List<String> _stringList(String raw) {
  try {
    final Object decoded = jsonDecode(raw) as Object;
    if (decoded is! List) {
      return const <String>[];
    }
    return <String>[
      for (final Object? item in decoded)
        if (item is String) item,
    ];
  } on FormatException {
    return const <String>[];
  }
}

Map<String, String> _stringMap(String raw) {
  try {
    final Object decoded = jsonDecode(raw) as Object;
    if (decoded is! Map) {
      return const <String, String>{};
    }
    final Map<String, String> out = <String, String>{};
    for (final MapEntry<Object?, Object?> entry in decoded.entries) {
      final Object? key = entry.key;
      final Object? value = entry.value;
      if (key is String) {
        out[key] = value?.toString() ?? '';
      }
    }
    return out;
  } on FormatException {
    return const <String, String>{};
  }
}
