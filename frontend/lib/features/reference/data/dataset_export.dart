import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/storage_root.dart';

import '../domain/reference_repository.dart';

/// Writes a dataset back out as CSV or JSON, streaming to the target file.
abstract final class DatasetExport {
  /// Streams pages into an atomic export, then hands it to the platform.
  /// The browser only buffers the final download, as its download API requires.
  static Future<Result<String?>> download({
    required ReferenceDataset dataset,
    required ReferenceRepository repository,
    required DownloadService downloads,
    required StorageRoot storageRoot,
    required String projectFolder,
    required String exportId,
    required bool json,
    CancellationToken? cancel,
  }) async {
    final String extension = json ? 'json' : 'csv';
    final String name;
    try {
      name = '${PathSanitizer.sanitiseSegment(dataset.name)}.$extension';
    } on Failure catch (nameFailure) {
      return FailureResult<String?>(nameFailure);
    }
    final String path = 'projects/$projectFolder/exports/$exportId-$name';
    final Result<WrittenFile> written = await FileWriter(
      storageRoot: storageRoot,
    ).write(_streamRows(dataset, repository, json, cancel), path);
    if (written is FailureResult<WrittenFile>) {
      return FailureResult<String?>(written.failure);
    }
    final String mime = json ? 'application/json' : 'text/csv';
    if (!kIsWeb) {
      return downloads.saveStored(
        relativePath: path,
        fileName: name,
        mimeType: mime,
        subfolder: projectFolder,
      );
    }
    final Result<Uint8List> bytes = await FileReader(
      storageRoot: storageRoot,
    ).read(path);
    return bytes.fold(
      FailureResult<String?>.new,
      (Uint8List value) =>
          downloads.save(fileName: name, bytes: value, mimeType: mime),
    );
  }

  /// Writes [rows] as CSV. Columns follow [dataset.columns] with the key first.
  static Future<Result<void>> writeCsv({
    required String path,
    required ReferenceDataset dataset,
    required List<ReferenceRow> rows,
    void Function(double)? onProgress,
    CancellationToken? cancel,
  }) {
    return _write(
      path: path,
      payload: <String, Object?>{
        'format': 'csv',
        'columns': _orderedColumns(dataset),
        'rows': _rowMaps(dataset, rows),
      },
      onProgress: onProgress,
      cancel: cancel,
    );
  }

  /// Writes [rows] as a JSON array of objects.
  static Future<Result<void>> writeJson({
    required String path,
    required ReferenceDataset dataset,
    required List<ReferenceRow> rows,
    void Function(double)? onProgress,
    CancellationToken? cancel,
  }) {
    return _write(
      path: path,
      payload: <String, Object?>{
        'format': 'json',
        'columns': _orderedColumns(dataset),
        'rows': _rowMaps(dataset, rows),
      },
      onProgress: onProgress,
      cancel: cancel,
    );
  }

  /// Builds CSV text in-process (tests and round-trips).
  static String csvText({
    required ReferenceDataset dataset,
    required List<ReferenceRow> rows,
  }) {
    return _csvOf(_orderedColumns(dataset), _rowMaps(dataset, rows));
  }

  /// Builds JSON text in-process (tests and round-trips).
  static String jsonText({
    required ReferenceDataset dataset,
    required List<ReferenceRow> rows,
  }) {
    return const JsonEncoder.withIndent('  ').convert(_rowMaps(dataset, rows));
  }
}

Stream<List<int>> _streamRows(
  ReferenceDataset dataset,
  ReferenceRepository repository,
  bool json,
  CancellationToken? cancel,
) async* {
  final List<String> columns = <String>[
    ..._orderedColumns(dataset),
    'addedOnDevice',
  ];
  yield utf8.encode(json ? '[' : '${columns.map(_escape).join(',')}\n');
  int offset = 0;
  bool first = true;
  while (true) {
    if (cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
    final Result<List<ReferenceRow>> loaded = await repository.pageRows(
      datasetId: dataset.id,
      offset: offset,
      limit: AppConstants.lists.pageSize,
    );
    final List<ReferenceRow> rows = switch (loaded) {
      Success<List<ReferenceRow>>(:final List<ReferenceRow> value) => value,
      FailureResult<List<ReferenceRow>>(failure: final Failure pageFailure) =>
        throw pageFailure,
    };
    if (rows.isEmpty) {
      break;
    }
    final Result<List<int>> chunk = await runIsolate(_encodeRows, (
      rows: _rowMaps(dataset, rows),
      columns: columns,
      json: json,
      first: first,
    ), cancel: cancel);
    yield switch (chunk) {
      Success<List<int>>(:final List<int> value) => value,
      FailureResult<List<int>>(failure: final Failure encodeFailure) =>
        throw encodeFailure,
    };
    first = false;
    offset += rows.length;
  }
  if (json) {
    yield utf8.encode(']');
  }
}

List<int> _encodeRows(
  ({
    List<Map<String, Object?>> rows,
    List<String> columns,
    bool json,
    bool first,
  })
  input,
) {
  if (input.json) {
    return utf8.encode(
      '${input.first ? '' : ','}${input.rows.map(jsonEncode).join(',')}',
    );
  }
  return utf8.encode(
    '${input.rows.map((Map<String, Object?> row) => input.columns.map((String column) => _escape('${row[column] ?? ''}')).join(',')).join('\n')}\n',
  );
}

Future<Result<void>> _write({
  required String path,
  required Map<String, Object?> payload,
  void Function(double)? onProgress,
  CancellationToken? cancel,
}) async {
  final Result<Object> written = await runIsolate(
    _writeInIsolate,
    <String, Object?>{'path': path, ...payload},
    onProgress: onProgress,
    cancel: cancel,
  );
  return switch (written) {
    FailureResult<Object>(:final Failure failure) => FailureResult<void>(
      failure,
    ),
    Success<Object>(:final Object value) =>
      value == true
          ? const Success<void>(null)
          : const FailureResult<void>(
              StorageFailure(
                message: 'The export could not be written.',
                recoveryAction: 'Free up space and try again.',
              ),
            ),
  };
}

Object _writeInIsolate(Map<String, Object?> message) {
  try {
    final String path = message['path']! as String;
    final String format = message['format']! as String;
    final List<String> columns = <String>[
      for (final Object? item
          in (message['columns'] as List? ?? const <Object>[]))
        if (item is String) item,
    ];
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    for (final Object? item in (message['rows'] as List? ?? const <Object>[])) {
      if (item is Map) {
        rows.add(Map<String, Object?>.from(item));
      }
    }
    final String body = format == 'json'
        ? const JsonEncoder.withIndent('  ').convert(rows)
        : _csvOf(columns, rows);
    File(path).writeAsStringSync(body);
    IsolateRunner.reportProgress(1);
    return true;
  } on Object {
    return false;
  }
}

List<String> _orderedColumns(ReferenceDataset dataset) {
  final List<String> ordered = <String>[dataset.keyColumn];
  for (final String column in dataset.columns) {
    if (column != dataset.keyColumn) {
      ordered.add(column);
    }
  }
  return ordered;
}

List<Map<String, Object?>> _rowMaps(
  ReferenceDataset dataset,
  List<ReferenceRow> rows,
) {
  final List<String> columns = _orderedColumns(dataset);
  return <Map<String, Object?>>[
    for (final ReferenceRow row in rows)
      <String, Object?>{
        for (final String column in columns)
          column: column == dataset.keyColumn
              ? row.key
              : (row.values[column] ?? ''),
        if (row.addedOnDevice) 'addedOnDevice': true,
      },
  ];
}

String _csvOf(List<String> columns, List<Map<String, Object?>> rows) {
  final StringBuffer buffer = StringBuffer();
  final List<String> header = <String>[
    ...columns,
    if (rows.any((Map<String, Object?> r) => r['addedOnDevice'] == true))
      'addedOnDevice',
  ];
  buffer.writeln(header.map(_escape).join(','));
  for (final Map<String, Object?> row in rows) {
    buffer.writeln(
      <String>[
        for (final String column in header) _escape('${row[column] ?? ''}'),
      ].join(','),
    );
  }
  return buffer.toString();
}

String _escape(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
