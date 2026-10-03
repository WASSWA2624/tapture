import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/dataset_import_draft.dart';
import '../domain/reference_dataset.dart';

/// Parses a JSON array of objects into a [DatasetImportDraft].
///
/// Columns are the union of the objects' keys in first-seen order; a key an
/// object lacks reads as empty rather than dropping the row.
abstract final class DatasetJsonImport {
  /// Streams [path] on a worker isolate and builds the draft there. The
  /// file is decoded a chunk at a time, and [onProgress] hears the share
  /// read and then the rows mapped, every [AppConstants.datasets]
  /// `progressRows` rows.
  static Future<Result<DatasetImportDraft>> parse(
    String path, {
    String? projectId,
    String? name,
    Clock clock = const SystemClock(),
    void Function(double)? onProgress,
    CancellationToken? cancel,
  }) async {
    final Result<Result<DatasetImportDraft>> parsed = await runIsolate(
      _parseFile,
      (
        path: path,
        projectId: projectId,
        name: name,
        importedAt: clock.nowUtc(),
      ),
      onProgress: onProgress,
      cancel: cancel,
    );
    return parsed.fold(
      FailureResult<DatasetImportDraft>.new,
      (Result<DatasetImportDraft> draft) => draft,
    );
  }

  /// Parses [text] on the calling isolate: browser bytes already on a
  /// worker, and round-trips.
  static Result<DatasetImportDraft> parseText(
    String text, {
    required String sourceFile,
    String? projectId,
    String? name,
    DateTime? importedAt,
  }) {
    try {
      final String body = text.startsWith('﻿') ? text.substring(1) : text;
      return Success<DatasetImportDraft>(
        _draftOf(
          jsonDecode(body),
          sourceFile: sourceFile,
          projectId: projectId,
          name: name,
          importedAt: importedAt ?? const SystemClock().nowUtc(),
        ),
      );
    } on FormatException {
      return FailureResult<DatasetImportDraft>(_invalidJson);
    } on Failure catch (parseFailure) {
      return FailureResult<DatasetImportDraft>(parseFailure);
    }
  }
}

/// What the worker isolate is asked to read.
typedef _FileJob = ({
  String path,
  String? projectId,
  String? name,
  DateTime importedAt,
});

Result<DatasetImportDraft> _parseFile(_FileJob job) {
  RandomAccessFile? file;
  try {
    file = File(job.path).openSync();
    final int total = file.lengthSync();
    final _Decoded decoded = _Decoded();
    final Sink<List<int>> bytes = const Utf8Decoder()
        .fuse<Object?>(const JsonDecoder())
        .startChunkedConversion(decoded);
    final Uint8List buffer = Uint8List(AppConstants.datasets.readChunkBytes);
    int read = 0;
    while (true) {
      final int count = file.readIntoSync(buffer);
      if (count == 0) {
        break;
      }
      // A byte-order mark is not JSON; skip it before the parser sees it.
      final int start = read == 0 && _hasBom(buffer, count) ? 3 : 0;
      read += count;
      bytes.add(buffer.sublist(start, count));
      IsolateRunner.reportProgress(
        total == 0 ? _readShare : _readShare * read / total,
      );
    }
    bytes.close();
    return Success<DatasetImportDraft>(
      _draftOf(
        decoded.value,
        sourceFile: job.path,
        projectId: job.projectId,
        name: job.name,
        importedAt: job.importedAt,
      ),
    );
  } on Failure catch (readFailure) {
    return FailureResult<DatasetImportDraft>(readFailure);
  } on FormatException {
    return FailureResult<DatasetImportDraft>(_invalidJson);
  } on FileSystemException {
    return FailureResult<DatasetImportDraft>(_unreadable);
  } finally {
    file?.closeSync();
  }
}

/// Holds the one value a chunked JSON decode produces.
final class _Decoded implements Sink<Object?> {
  Object? value;

  @override
  void add(Object? data) {
    value = data;
  }

  @override
  void close() {}
}

bool _hasBom(Uint8List bytes, int count) {
  return count >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF;
}

/// The draft [decoded] lands as: an array of objects, keys unioned.
DatasetImportDraft _draftOf(
  Object? decoded, {
  required String sourceFile,
  required DateTime importedAt,
  String? projectId,
  String? name,
}) {
  if (decoded is! List) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureJSONDatasetsMustBeAnArrayOf,
      localizedRecovery: Copy.messages.failureWrapTheRowsInAnArrayAnd,
    );
  }
  final List<String> columns = <String>[];
  final Set<String> seen = <String>{};
  final List<Map<Object?, Object?>> objects = <Map<Object?, Object?>>[];
  for (final Object? item in decoded) {
    if (item is! Map) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.failureEveryJSONRowMustBeAnObject,
        localizedRecovery: Copy.messages.failureRemoveNonObjectRowsAndImportThe,
      );
    }
    objects.add(item);
    for (final Object? key in item.keys) {
      if (key is String && seen.add(key)) {
        columns.add(key);
      }
    }
  }
  if (columns.isEmpty) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThatFileHasNoColumns,
      localizedRecovery: Copy.messages.failureAddKeysToTheObjectsAndTry,
    );
  }
  final List<Map<String, String>> rows = <Map<String, String>>[];
  for (int index = 0; index < objects.length; index++) {
    final Map<Object?, Object?> item = objects[index];
    rows.add(<String, String>{
      for (final String column in columns) column: '${item[column] ?? ''}',
    });
    if ((index + 1) % AppConstants.datasets.progressRows == 0) {
      IsolateRunner.reportProgress(
        _readShare + (1 - _readShare) * (index + 1) / objects.length,
      );
    }
  }
  return DatasetDraft.build(
    columns: columns,
    rows: rows,
    source: DatasetSource.json,
    sourceFile: sourceFile,
    importedAt: importedAt,
    projectId: projectId,
    name: name,
  );
}

/// The share of progress reading the file stands for; mapping rows is the
/// rest.
const double _readShare = 0.5;

final ValidationFailure _invalidJson = ValidationFailure(
  localizedMessage: Copy.messages.failureThatJSONIsNotValid,
  localizedRecovery: Copy.messages.failureFixTheJSONArrayAndImportIt,
);

final StorageFailure _unreadable = StorageFailure(
  localizedMessage: Copy.messages.failureThatJSONCouldNotBeRead,
  localizedRecovery: Copy.messages.failureCheckTheFileAndTryAgain,
);
