import 'dart:convert';
import 'dart:io';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/reference_dataset.dart';
import '../domain/reference_row.dart';
import 'dataset_csv_import.dart';

/// Parses a JSON array of objects into a draft [ReferenceDataset].
abstract final class DatasetJsonImport {
  /// Streams [path] off the UI thread.
  static Future<Result<DatasetImportDraft>> parse(
    String path, {
    String? projectId,
    String? name,
    void Function(double)? onProgress,
    CancellationToken? cancel,
  }) async {
    final Result<Object> parsed = await runIsolate(
      _parseInIsolate,
      <String, Object?>{'path': path},
      onProgress: onProgress,
      cancel: cancel,
    );
    return switch (parsed) {
      FailureResult<Object>(:final Failure failure) =>
        FailureResult<DatasetImportDraft>(failure),
      Success<Object>(:final Object value) => _draftOf(
        value,
        path: path,
        projectId: projectId,
        name: name,
      ),
    };
  }

  /// Parses [text] in-process (tests and round-trips).
  static Result<DatasetImportDraft> parseText(
    String text, {
    required String sourceFile,
    String? projectId,
    String? name,
    DateTime? importedAt,
  }) {
    try {
      final ({List<String> columns, List<Map<String, String>> rows}) parsed =
          _parseJson(text);
      return Success<DatasetImportDraft>(
        _toDraft(
          columns: parsed.columns,
          rows: parsed.rows,
          sourceFile: sourceFile,
          source: DatasetSource.json,
          projectId: projectId,
          name: name,
          importedAt: importedAt,
        ),
      );
    } on Failure catch (failure) {
      return FailureResult<DatasetImportDraft>(failure);
    }
  }
}

Object _parseInIsolate(Map<String, Object?> message) {
  final Object? path = message['path'];
  if (path is! String) {
    return <String, Object?>{'ok': false};
  }
  try {
    final String text = File(path).readAsStringSync();
    final ({List<String> columns, List<Map<String, String>> rows}) parsed =
        _parseJson(text);
    IsolateRunner.reportProgress(1);
    return <String, Object?>{
      'ok': true,
      'columns': parsed.columns,
      'rows': parsed.rows,
    };
  } on Failure catch (failure) {
    return <String, Object?>{
      'ok': false,
      'message': failure.message,
      'recovery': failure.recoveryAction,
    };
  } on Object {
    return <String, Object?>{'ok': false};
  }
}

Result<DatasetImportDraft> _draftOf(
  Object value, {
  required String path,
  String? projectId,
  String? name,
}) {
  if (value is! Map || value['ok'] != true) {
    final Map<Object?, Object?> map = value is Map
        ? Map<Object?, Object?>.from(value)
        : const <Object?, Object?>{};
    final Object? message = map['message'];
    if (message is String) {
      return FailureResult<DatasetImportDraft>(
        ValidationFailure(
          message: message,
          recoveryAction:
              map['recovery'] as String? ?? 'Fix the file and try again.',
        ),
      );
    }
    return const FailureResult<DatasetImportDraft>(
      ValidationFailure(
        message: 'That JSON could not be read.',
        recoveryAction: 'Use an array of objects and try again.',
      ),
    );
  }
  final Map<Object?, Object?> ok = Map<Object?, Object?>.from(value);
  final List<String> columns = <String>[
    for (final Object? item in (ok['columns'] as List? ?? const <Object>[]))
      if (item is String) item,
  ];
  final List<Map<String, String>> rows = <Map<String, String>>[];
  for (final Object? item in (ok['rows'] as List? ?? const <Object>[])) {
    if (item is Map) {
      rows.add(<String, String>{
        for (final MapEntry<Object?, Object?> e in item.entries)
          if (e.key is String) e.key! as String: '${e.value ?? ''}',
      });
    }
  }
  return Success<DatasetImportDraft>(
    _toDraft(
      columns: columns,
      rows: rows,
      sourceFile: path,
      source: DatasetSource.json,
      projectId: projectId,
      name: name,
    ),
  );
}

DatasetImportDraft _toDraft({
  required List<String> columns,
  required List<Map<String, String>> rows,
  required String sourceFile,
  required DatasetSource source,
  String? projectId,
  String? name,
  DateTime? importedAt,
}) {
  if (columns.isEmpty) {
    throw const ValidationFailure(
      message: 'That file has no columns.',
      recoveryAction: 'Add keys to the objects and try again.',
    );
  }
  final String keyGuess = columns.first;
  final List<ReferenceRow> mapped = <ReferenceRow>[
    for (final Map<String, String> row in rows)
      ReferenceRow(
        id: '',
        datasetId: '',
        key: row[keyGuess] ?? '',
        values: <String, String>{
          for (final String column in columns) column: row[column] ?? '',
        },
      ),
  ];
  final Map<String, int> duplicateCounts = <String, int>{
    for (final String column in columns) column: _dups(rows, column),
  };
  final Map<String, List<String>> samples = <String, List<String>>{
    for (final String column in columns)
      column: <String>[
        for (final Map<String, String> row in rows.take(3)) row[column] ?? '',
      ],
  };
  final String fileName = sourceFile.replaceAll('\\', '/').split('/').last;
  return (
    dataset: ReferenceDataset(
      id: '',
      name: (name == null || name.isEmpty)
          ? fileName.replaceAll(RegExp(r'\.[^.]+$'), '')
          : name,
      keyColumn: keyGuess,
      columns: columns,
      source: source,
      importedAt: importedAt ?? DateTime.now().toUtc(),
      rowCount: mapped.length,
      projectId: projectId,
      sourceFile: sourceFile,
    ),
    rows: mapped,
    duplicateCounts: duplicateCounts,
    samples: samples,
  );
}

int _dups(List<Map<String, String>> rows, String column) {
  final Map<String, int> counts = <String, int>{};
  for (final Map<String, String> row in rows) {
    final String value = row[column] ?? '';
    counts[value] = (counts[value] ?? 0) + 1;
  }
  int dups = 0;
  for (final int count in counts.values) {
    if (count > 1) {
      dups += count - 1;
    }
  }
  return dups;
}

({List<String> columns, List<Map<String, String>> rows}) _parseJson(
  String text,
) {
  final Object decoded = jsonDecode(text) as Object;
  if (decoded is! List) {
    throw const ValidationFailure(
      message: 'JSON datasets must be an array of objects.',
      recoveryAction: 'Wrap the rows in an array and try again.',
    );
  }
  final List<String> columns = <String>[];
  final Set<String> seen = <String>{};
  final List<Map<String, String>> rows = <Map<String, String>>[];
  for (final Object? item in decoded) {
    if (item is! Map) {
      continue;
    }
    for (final Object? key in item.keys) {
      if (key is String && seen.add(key)) {
        columns.add(key);
      }
    }
    rows.add(<String, String>{
      for (final String column in columns) column: '${item[column] ?? ''}',
    });
  }
  // Fill columns discovered later into earlier rows.
  for (int i = 0; i < rows.length; i++) {
    final Map<String, String> row = Map<String, String>.of(rows[i]);
    for (final String column in columns) {
      row.putIfAbsent(column, () => '');
    }
    rows[i] = row;
  }
  return (columns: columns, rows: rows);
}
