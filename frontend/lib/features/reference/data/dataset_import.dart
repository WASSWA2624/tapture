import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/picked_document.dart';

import 'dataset_csv_import.dart';
import 'dataset_json_import.dart';
import 'dataset_xlsx_import.dart';

/// Routes chosen documents to the existing dataset readers on every platform.
abstract final class DatasetImport {
  /// Validates the selection before parsing and computing key summaries.
  static Future<Result<DatasetImportDraft>> read(
    PickedDocument document, {
    String? projectId,
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async {
    final String extension = document.name.split('.').last.toLowerCase();
    if (!const <String>{'csv', 'json', 'xlsx'}.contains(extension) ||
        document.byteLength <= 0 ||
        document.byteLength > AppConstants.imports.spreadsheetMaxBytes) {
      return const FailureResult<DatasetImportDraft>(
        ValidationFailure(
          message:
              'Choose a CSV, JSON or XLSX table within the import size limit.',
          recoveryAction:
              'Choose another file or split this table into smaller files.',
        ),
      );
    }
    if (document case PickedFile(:final File file)) {
      // Named like the browser readers name a dataset: without the extension.
      final String name = document.name.replaceAll(_extension, '');
      return switch (extension) {
        'xlsx' => DatasetXlsxImport.parse(
          file.path,
          projectId: projectId,
          name: name,
          cancel: cancel,
          onProgress: onProgress,
        ),
        'csv' => DatasetCsvImport.parse(
          file.path,
          projectId: projectId,
          name: name,
          cancel: cancel,
          onProgress: onProgress,
        ),
        _ => DatasetJsonImport.parse(
          file.path,
          projectId: projectId,
          name: name,
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
        cancel: cancel,
        onProgress: onProgress,
      );
    }
    final Result<Result<DatasetImportDraft>> parsed = await runIsolate(
      _parseText,
      (
        bytes: bytes,
        name: document.name,
        projectId: projectId,
        json: extension == 'json',
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
  ({Uint8List bytes, String name, String? projectId, bool json}) input,
) {
  try {
    final String text = utf8.decode(input.bytes).replaceFirst('\uFEFF', '');
    if (text.contains('\u0000')) {
      return const FailureResult<DatasetImportDraft>(_unreadableText);
    }
    return input.json
        ? DatasetJsonImport.parseText(
            text,
            sourceFile: input.name,
            projectId: input.projectId,
          )
        : DatasetCsvImport.parseText(
            text,
            sourceFile: input.name,
            projectId: input.projectId,
          );
  } on FormatException {
    return const FailureResult<DatasetImportDraft>(_unreadableText);
  }
}

/// A file name's final extension, dot included.
final RegExp _extension = RegExp(r'\.[^.]+$');

/// Bytes that are not UTF-8 text, or that carry NUL characters.
const ValidationFailure _unreadableText = ValidationFailure(
  message: 'That table could not be read as text.',
  recoveryAction: 'Save it as UTF-8 CSV or a JSON array and try again.',
);
