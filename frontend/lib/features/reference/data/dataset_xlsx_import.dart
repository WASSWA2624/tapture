import 'dart:typed_data';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/import/header_detection.dart';
import 'package:tapture/core/import/workbook_reader.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/dataset_import_draft.dart';
import '../domain/reference_dataset.dart';

/// Parses a spreadsheet into a [DatasetImportDraft] through the shared
/// [WorkbookReader] and [HeaderDetection], never a second copy of either
/// (FE-CONS-01, FE-STR-09).
abstract final class DatasetXlsxImport {
  /// Reads browser-selected spreadsheet [bytes] the same way.
  static Future<Result<DatasetImportDraft>> parseBytes(
    Uint8List bytes, {
    required String sourceName,
    String? projectId,
    String? name,
    Clock clock = const SystemClock(),
    void Function(double)? onProgress,
    CancellationToken? cancel,
  }) async {
    final Result<WorkbookSnapshot> opened = await WorkbookReader.openBytes(
      bytes,
      sourceName: sourceName,
      onProgress: onProgress,
      cancel: cancel,
    );
    return _draftOf(
      opened,
      sourceFile: sourceName,
      projectId: projectId,
      name: name,
      importedAt: clock.nowUtc(),
      sheetIndex: 0,
      cancel: cancel,
    );
  }

  /// Opens [path] on a worker isolate, then builds the draft of sheet
  /// [sheetIndex] on another, so neither step blocks the interface.
  static Future<Result<DatasetImportDraft>> parse(
    String path, {
    String? projectId,
    String? name,
    int sheetIndex = 0,
    Clock clock = const SystemClock(),
    void Function(double)? onProgress,
    CancellationToken? cancel,
  }) async {
    final Result<WorkbookSnapshot> opened = await WorkbookReader.open(
      path,
      onProgress: onProgress,
      cancel: cancel,
    );
    return _draftOf(
      opened,
      sourceFile: path,
      projectId: projectId,
      name: name,
      importedAt: clock.nowUtc(),
      sheetIndex: sheetIndex,
      cancel: cancel,
    );
  }
}

/// What the worker isolate builds a draft from.
typedef _SheetJob = ({
  WorkbookSnapshot book,
  int sheetIndex,
  String sourceFile,
  String? projectId,
  String? name,
  DateTime importedAt,
});

Future<Result<DatasetImportDraft>> _draftOf(
  Result<WorkbookSnapshot> opened, {
  required String sourceFile,
  required String? projectId,
  required String? name,
  required DateTime importedAt,
  required int sheetIndex,
  CancellationToken? cancel,
}) async {
  switch (opened) {
    case FailureResult<WorkbookSnapshot>(:final Failure failure):
      return FailureResult<DatasetImportDraft>(failure);
    case Success<WorkbookSnapshot>(:final WorkbookSnapshot value):
      final Result<Result<DatasetImportDraft>> built =
          await runIsolate(_sheetDraft, (
            book: value,
            sheetIndex: sheetIndex,
            sourceFile: sourceFile,
            projectId: projectId,
            name: name,
            importedAt: importedAt,
          ), cancel: cancel);
      return built.fold(
        FailureResult<DatasetImportDraft>.new,
        (Result<DatasetImportDraft> draft) => draft,
      );
  }
}

Result<DatasetImportDraft> _sheetDraft(_SheetJob job) {
  final List<WorkbookSheet> sheets = job.book.sheets;
  if (sheets.isEmpty) {
    return FailureResult<DatasetImportDraft>(
      ValidationFailure(
        localizedMessage: Copy.messages.failureThatWorkbookHasNoSheets,
        localizedRecovery: Copy.messages.failureChooseAWorkbookWithASheetOf,
      ),
    );
  }
  final WorkbookSheet sheet =
      sheets[job.sheetIndex < 0 || job.sheetIndex >= sheets.length
          ? 0
          : job.sheetIndex];
  final HeaderGuess header = sheet.header.labels.isNotEmpty
      ? sheet.header
      : HeaderDetection.choose(sheet.rows);
  if (header.labels.isEmpty) {
    return FailureResult<DatasetImportDraft>(
      ValidationFailure(
        localizedMessage: Copy.messages.failureThatSheetHasNoHeaderRow,
        localizedRecovery: Copy.messages.failureAddAHeaderRowAndTryAgain,
      ),
    );
  }
  final List<String> columns = DatasetDraft.uniqueColumns(header.labels);
  final List<Map<String, String>> rows = <Map<String, String>>[
    // The header's row number is 1-based, so it is the first data row's
    // index.
    for (final List<String> line in sheet.rows.skip(header.rowNumber))
      if (line.any((String cell) => cell.trim().isNotEmpty))
        <String, String>{
          for (int column = 0; column < columns.length; column++)
            columns[column]: column < line.length ? line[column] : '',
        },
  ];
  try {
    return Success<DatasetImportDraft>(
      DatasetDraft.build(
        columns: columns,
        rows: rows,
        source: DatasetSource.xlsx,
        sourceFile: job.sourceFile,
        importedAt: job.importedAt,
        projectId: job.projectId,
        name: job.name,
      ),
    );
  } on Failure catch (buildFailure) {
    return FailureResult<DatasetImportDraft>(buildFailure);
  }
}
