import 'dart:convert';

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

import '../domain/dataset_import_draft.dart';
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

  /// [rows] as the CSV [download] writes, built in-process for round-trips.
  static String csvText({
    required ReferenceDataset dataset,
    required List<ReferenceRow> rows,
  }) {
    final List<String> columns = _exportColumns(dataset);
    return '${_csvHeader(columns)}'
        '${utf8.decode(_encodeRows((rows: _rowMaps(dataset, rows), columns: columns, json: false, first: true)))}';
  }

  /// [rows] as the JSON array [download] writes, built in-process for
  /// round-trips.
  static String jsonText({
    required ReferenceDataset dataset,
    required List<ReferenceRow> rows,
  }) {
    return '[${utf8.decode(_encodeRows((rows: _rowMaps(dataset, rows), columns: _exportColumns(dataset), json: true, first: true)))}]';
  }
}

Stream<List<int>> _streamRows(
  ReferenceDataset dataset,
  ReferenceRepository repository,
  bool json,
  CancellationToken? cancel,
) async* {
  final List<String> columns = _exportColumns(dataset);
  yield utf8.encode(json ? '[' : _csvHeader(columns));
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

/// The dataset's columns with the key first, then the device-row marker the
/// receiving system tells added rows apart by.
List<String> _exportColumns(ReferenceDataset dataset) {
  return <String>[
    ..._orderedColumns(dataset),
    DatasetDraft.addedOnDeviceColumn,
  ];
}

String _csvHeader(List<String> columns) =>
    '${columns.map(_escape).join(',')}\n';

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
        if (row.addedOnDevice) DatasetDraft.addedOnDeviceColumn: true,
      },
  ];
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
