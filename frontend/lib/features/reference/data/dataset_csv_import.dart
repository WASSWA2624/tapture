import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/reference_dataset.dart';
import '../domain/reference_row.dart';

/// Parses a CSV file into a draft [ReferenceDataset] and its rows.
abstract final class DatasetCsvImport {
  /// Streams [path] off the UI thread. Progress is a row count fraction.
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
          _parseCsv(text);
      return Success<DatasetImportDraft>(
        _toDraft(
          columns: parsed.columns,
          rows: parsed.rows,
          sourceFile: sourceFile,
          source: DatasetSource.csv,
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

/// Parsed header and rows before the key-column screen saves them.
typedef DatasetImportDraft = ({
  ReferenceDataset dataset,
  List<ReferenceRow> rows,
  Map<String, int> duplicateCounts,
  Map<String, List<String>> samples,
});

Object _parseInIsolate(Map<String, Object?> message) {
  final Object? path = message['path'];
  if (path is! String) {
    return <String, Object?>{'ok': false, 'error': 'path'};
  }
  try {
    final Uint8List bytes = File(path).readAsBytesSync();
    final String text = _decodeBom(bytes);
    final ({List<String> columns, List<Map<String, String>> rows}) parsed =
        _parseCsv(text);
    IsolateRunner.reportProgress(1);
    return <String, Object?>{
      'ok': true,
      'columns': parsed.columns,
      'rows': <Map<String, String>>[
        for (final Map<String, String> row in parsed.rows) row,
      ],
    };
  } on Failure catch (failure) {
    return <String, Object?>{
      'ok': false,
      'message': failure.message,
      'recovery': failure.recoveryAction,
    };
  } on Object {
    return <String, Object?>{'ok': false, 'error': 'io'};
  }
}

Result<DatasetImportDraft> _draftOf(
  Object value, {
  required String path,
  String? projectId,
  String? name,
}) {
  if (value is! Map) {
    return const FailureResult<DatasetImportDraft>(_corrupt);
  }
  final Map<Object?, Object?> map = value;
  if (map['ok'] != true) {
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
    return const FailureResult<DatasetImportDraft>(_corrupt);
  }
  final List<String> columns = <String>[
    for (final Object? item in (map['columns'] as List? ?? const <Object>[]))
      if (item is String) item,
  ];
  final List<Map<String, String>> rows = <Map<String, String>>[];
  for (final Object? item in (map['rows'] as List? ?? const <Object>[])) {
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
      source: DatasetSource.csv,
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
      recoveryAction: 'Add a header row and try again.',
    );
  }
  final String keyGuess = columns.first;
  final List<ReferenceRow> mapped = <ReferenceRow>[
    for (int i = 0; i < rows.length; i++)
      ReferenceRow(
        id: '',
        datasetId: '',
        key: rows[i][keyGuess] ?? '',
        values: <String, String>{
          for (final String column in columns) column: rows[i][column] ?? '',
        },
      ),
  ];
  final Map<String, int> duplicateCounts = <String, int>{
    for (final String column in columns) column: _duplicateCount(rows, column),
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

int _duplicateCount(List<Map<String, String>> rows, String column) {
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

String _decodeBom(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return utf8.decode(bytes.sublist(3));
  }
  return utf8.decode(bytes);
}

({List<String> columns, List<Map<String, String>> rows}) _parseCsv(
  String text,
) {
  final String body = text.replaceFirst(RegExp(r'^\uFEFF'), '');
  final List<List<String>> grid = _readGrid(body);
  if (grid.isEmpty) {
    throw const ValidationFailure(
      message: 'That file is empty.',
      recoveryAction: 'Choose a CSV with a header and rows.',
    );
  }
  final List<String> columns = <String>[
    for (int i = 0; i < grid.first.length; i++)
      _uniqueHeader(grid.first[i].trim(), i, grid.first),
  ];
  final List<Map<String, String>> rows = <Map<String, String>>[];
  for (int r = 1; r < grid.length; r++) {
    final List<String> line = grid[r];
    if (line.every((String cell) => cell.trim().isEmpty)) {
      continue;
    }
    final Map<String, String> row = <String, String>{};
    for (int c = 0; c < columns.length; c++) {
      row[columns[c]] = c < line.length ? line[c] : '';
    }
    rows.add(row);
  }
  return (columns: columns, rows: rows);
}

String _uniqueHeader(String label, int index, List<String> headers) {
  final String base = label.isEmpty ? 'column_${index + 1}' : label;
  int suffix = 2;
  String candidate = base;
  final Set<String> earlier = <String>{
    for (int i = 0; i < index; i++)
      headers[i].trim().isEmpty ? 'column_${i + 1}' : headers[i].trim(),
  };
  while (earlier.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

List<List<String>> _readGrid(String text) {
  final String delimiter = _detectDelimiter(text);
  final List<List<String>> rows = <List<String>>[];
  final List<String> current = <String>[];
  final StringBuffer cell = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < text.length; i++) {
    final String ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(ch);
      }
      continue;
    }
    if (ch == '"') {
      inQuotes = true;
      continue;
    }
    if (ch == delimiter) {
      current.add(cell.toString());
      cell.clear();
      continue;
    }
    if (ch == '\n') {
      current.add(cell.toString());
      cell.clear();
      rows.add(List<String>.of(current));
      current.clear();
      continue;
    }
    if (ch == '\r') {
      continue;
    }
    cell.write(ch);
  }
  if (cell.isNotEmpty || current.isNotEmpty) {
    current.add(cell.toString());
    rows.add(current);
  }
  return rows;
}

String _detectDelimiter(String text) {
  final String sample = text.split(RegExp(r'\r?\n')).first;
  final int commas = ','.allMatches(sample).length;
  final int semis = ';'.allMatches(sample).length;
  final int tabs = '\t'.allMatches(sample).length;
  if (semis > commas && semis >= tabs) {
    return ';';
  }
  if (tabs > commas && tabs > semis) {
    return '\t';
  }
  return ',';
}

const ValidationFailure _corrupt = ValidationFailure(
  message: 'That CSV could not be read.',
  recoveryAction: 'Check the file and try again.',
);
