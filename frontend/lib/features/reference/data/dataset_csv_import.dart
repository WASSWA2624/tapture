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

/// Parses a CSV table into a [DatasetImportDraft].
///
/// The delimiter is read from the header line (comma, semicolon or tab);
/// quoted values may hold the delimiter, line breaks and doubled quotes; a
/// byte-order mark is dropped; and blank lines are skipped without shifting
/// a column.
abstract final class DatasetCsvImport {
  /// Streams [path] on a worker isolate and builds the draft there, so a
  /// large file never blocks the interface. [onProgress] hears the share of
  /// the file read, every [AppConstants.datasets] `progressRows` rows.
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
  /// worker, and round-trips. Progress is reported the same way.
  static Result<DatasetImportDraft> parseText(
    String text, {
    required String sourceFile,
    String? projectId,
    String? name,
    DateTime? importedAt,
  }) {
    try {
      final _CsvTable table = _CsvTable();
      final int step = AppConstants.datasets.readChunkBytes;
      for (int start = 0; start < text.length; start += step) {
        final int end = start + step < text.length ? start + step : text.length;
        table.fraction = end / text.length;
        table.add(text.substring(start, end));
      }
      table.close();
      return Success<DatasetImportDraft>(
        table.draft(
          sourceFile: sourceFile,
          projectId: projectId,
          name: name,
          importedAt: importedAt ?? const SystemClock().nowUtc(),
        ),
      );
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
    final _CsvTable table = _CsvTable();
    final ByteConversionSink bytes = const Utf8Decoder().startChunkedConversion(
      table,
    );
    final Uint8List buffer = Uint8List(AppConstants.datasets.readChunkBytes);
    int read = 0;
    while (true) {
      final int count = file.readIntoSync(buffer);
      if (count == 0) {
        break;
      }
      read += count;
      table.fraction = total == 0 ? 1 : read / total;
      bytes.addSlice(buffer, 0, count, false);
    }
    bytes.close();
    return Success<DatasetImportDraft>(
      table.draft(
        sourceFile: job.path,
        projectId: job.projectId,
        name: job.name,
        importedAt: job.importedAt,
      ),
    );
  } on Failure catch (readFailure) {
    return FailureResult<DatasetImportDraft>(readFailure);
  } on FormatException {
    return FailureResult<DatasetImportDraft>(_notText);
  } on FileSystemException {
    return FailureResult<DatasetImportDraft>(_unreadable);
  } finally {
    file?.closeSync();
  }
}

/// Collects decoded text into a header and rows as it arrives, a chunk at a
/// time, so the file itself is never held whole.
final class _CsvTable implements Sink<String> {
  /// Share of the input consumed so far, reported with progress.
  double fraction = 0;

  final StringBuffer _head = StringBuffer();
  final StringBuffer _cell = StringBuffer();
  List<String> _row = <String>[];
  int? _delimiter;
  bool _inQuotes = false;
  bool _quoteSeen = false;
  List<String>? _columns;
  final List<Map<String, String>> _rows = <Map<String, String>>[];

  @override
  void add(String chunk) {
    if (_delimiter != null) {
      _consume(chunk);
      return;
    }
    // The delimiter is read from the header line, so text waits here until
    // that line has arrived whole.
    _head.write(chunk);
    final String head = _head.toString();
    if (head.contains('\n')) {
      _start(head);
    }
  }

  @override
  void close() {
    if (_delimiter == null) {
      _start(_head.toString());
    }
    if (_quoteSeen) {
      _inQuotes = false;
      _quoteSeen = false;
    }
    if (_inQuotes) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.failureAQuotedCSVValueIsUnfinished,
        localizedRecovery: Copy.messages.failureCloseTheQuotedValueAndImportThe,
      );
    }
    if (_cell.isNotEmpty || _row.isNotEmpty) {
      _endRow();
    }
  }

  /// The draft this table lands as.
  DatasetImportDraft draft({
    required String sourceFile,
    required DateTime importedAt,
    String? projectId,
    String? name,
  }) {
    final List<String>? columns = _columns;
    if (columns == null) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.failureThatFileIsEmpty,
        localizedRecovery: Copy.messages.failureChooseACSVWithAHeaderAnd,
      );
    }
    return DatasetDraft.build(
      columns: columns,
      rows: _rows,
      source: DatasetSource.csv,
      sourceFile: sourceFile,
      importedAt: importedAt,
      projectId: projectId,
      name: name,
    );
  }

  void _start(String head) {
    final String body = head.startsWith('﻿') ? head.substring(1) : head;
    _head.clear();
    _delimiter = _delimiterOf(body.split('\n').first);
    _consume(body);
  }

  void _consume(String text) {
    final int delimiter = _delimiter!;
    for (int index = 0; index < text.length; index++) {
      final int unit = text.codeUnitAt(index);
      if (_quoteSeen) {
        _quoteSeen = false;
        if (unit == _quote) {
          _cell.writeCharCode(_quote);
          continue;
        }
        _inQuotes = false;
      } else if (_inQuotes) {
        if (unit == _quote) {
          _quoteSeen = true;
        } else {
          _cell.writeCharCode(unit);
        }
        continue;
      }
      if (unit == _quote) {
        _inQuotes = true;
      } else if (unit == delimiter) {
        _row.add(_cell.toString());
        _cell.clear();
      } else if (unit == _newline) {
        _endRow();
      } else if (unit != _return) {
        _cell.writeCharCode(unit);
      }
    }
  }

  void _endRow() {
    _row.add(_cell.toString());
    _cell.clear();
    final List<String> cells = _row;
    _row = <String>[];
    final List<String>? columns = _columns;
    if (columns == null) {
      _columns = DatasetDraft.uniqueColumns(cells);
      return;
    }
    if (cells.every((String cell) => cell.trim().isEmpty)) {
      return;
    }
    _rows.add(<String, String>{
      for (int column = 0; column < columns.length; column++)
        columns[column]: column < cells.length ? cells[column] : '',
    });
    if (_rows.length % AppConstants.datasets.progressRows == 0) {
      IsolateRunner.reportProgress(fraction);
    }
  }
}

/// The delimiter [header] uses most: semicolon or tab when either outnumbers
/// commas, else comma.
int _delimiterOf(String header) {
  final int commas = ','.allMatches(header).length;
  final int semis = ';'.allMatches(header).length;
  final int tabs = '\t'.allMatches(header).length;
  if (semis > commas && semis >= tabs) {
    return _semicolon;
  }
  if (tabs > commas && tabs > semis) {
    return _tab;
  }
  return _comma;
}

const int _quote = 0x22;
const int _comma = 0x2C;
const int _semicolon = 0x3B;
const int _tab = 0x09;
const int _newline = 0x0A;
const int _return = 0x0D;

final ValidationFailure _notText = ValidationFailure(
  localizedMessage: Copy.messages.failureThatTableCouldNotBeReadAs,
  localizedRecovery: Copy.messages.failureSaveItAsUTFCSVAndTry,
);

final StorageFailure _unreadable = StorageFailure(
  localizedMessage: Copy.messages.failureThatCSVCouldNotBeRead,
  localizedRecovery: Copy.messages.failureCheckTheFileAndTryAgain,
);
