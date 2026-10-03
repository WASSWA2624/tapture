import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_validation.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/dataset_import_draft.dart';
import 'dataset_csv_import.dart';
import 'dataset_json_import.dart';
import 'dataset_xlsx_import.dart';

/// Routes a chosen document to the CSV, JSON or spreadsheet reader on every
/// platform. Each reads and builds its draft off the UI thread.
abstract final class DatasetImport {
  /// Validates the selection, then parses it into a draft named after the
  /// file. [onProgress] hears the share read; [clock] stamps the import.
  static Future<Result<DatasetImportDraft>> read(
    PickedDocument document, {
    String? projectId,
    Clock clock = const SystemClock(),
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async {
    final String extension = document.name.split('.').last.toLowerCase();
    if (!const <String>{'csv', 'json', 'xlsx'}.contains(extension) ||
        document.byteLength <= 0 ||
        document.byteLength > AppConstants.imports.spreadsheetMaxBytes) {
      return FailureResult<DatasetImportDraft>(
        ValidationFailure(
          localizedMessage: Copy.messages.failureChooseACSVJSONOrXLSXTable,
          localizedRecovery:
              Copy.messages.failureChooseAnotherFileOrSplitThisTable,
        ),
      );
    }
    // The one import gate reads the header and size before any parser runs.
    final Result<ImportKind> gate = await FileValidation().validateDocument(
      document,
      allowed: const <ImportKind>{ImportKind.spreadsheet},
    );
    if (gate case FailureResult<ImportKind>(:final Failure failure)) {
      return FailureResult<DatasetImportDraft>(failure);
    }
    // Named like every reader names a dataset: without the extension.
    final String name = document.name.replaceAll(_extension, '');
    if (document case PickedFile(:final File file)) {
      return switch (extension) {
        'xlsx' => DatasetXlsxImport.parse(
          file.path,
          projectId: projectId,
          name: name,
          clock: clock,
          cancel: cancel,
          onProgress: onProgress,
        ),
        'csv' => DatasetCsvImport.parse(
          file.path,
          projectId: projectId,
          name: name,
          clock: clock,
          cancel: cancel,
          onProgress: onProgress,
        ),
        _ => DatasetJsonImport.parse(
          file.path,
          projectId: projectId,
          name: name,
          clock: clock,
          cancel: cancel,
          onProgress: onProgress,
        ),
      };
    }
    final Uint8List bytes = (document as PickedBytes).bytes;
    if (extension == 'xlsx') {
      return DatasetXlsxImport.parseBytes(
        bytes,
        sourceName: document.name,
        projectId: projectId,
        name: name,
        clock: clock,
        cancel: cancel,
        onProgress: onProgress,
      );
    }
    final Result<Result<DatasetImportDraft>> parsed = await runIsolate(
      _parseText,
      (
        bytes: bytes,
        sourceFile: document.name,
        name: name,
        projectId: projectId,
        json: extension == 'json',
        importedAt: clock.nowUtc(),
      ),
      cancel: cancel,
      onProgress: onProgress,
    );
    return parsed.fold(
      FailureResult<DatasetImportDraft>.new,
      (Result<DatasetImportDraft> draft) => draft,
    );
  }
}

Result<DatasetImportDraft> _parseText(
  ({
    Uint8List bytes,
    String sourceFile,
    String name,
    String? projectId,
    bool json,
    DateTime importedAt,
  })
  input,
) {
  try {
    final String text = utf8.decode(input.bytes).replaceFirst('﻿', '');
    if (text.contains('\u0000')) {
      return FailureResult<DatasetImportDraft>(_unreadableText);
    }
    return input.json
        ? DatasetJsonImport.parseText(
            text,
            sourceFile: input.sourceFile,
            projectId: input.projectId,
            name: input.name,
            importedAt: input.importedAt,
          )
        : DatasetCsvImport.parseText(
            text,
            sourceFile: input.sourceFile,
            projectId: input.projectId,
            name: input.name,
            importedAt: input.importedAt,
          );
  } on FormatException {
    return FailureResult<DatasetImportDraft>(_unreadableText);
  }
}

/// A file name's final extension, dot included.
final RegExp _extension = RegExp(r'\.[^.]+$');

/// Bytes that are not UTF-8 text, or that carry NUL characters.
final ValidationFailure _unreadableText = ValidationFailure(
  localizedMessage: Copy.messages.failureThatTableCouldNotBeReadAs,
  localizedRecovery: Copy.messages.failureSaveItAsUTFCSVOrA,
);
