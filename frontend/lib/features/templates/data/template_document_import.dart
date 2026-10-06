import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/ooxml_package.dart';
import 'package:tapture/core/export/plain_text_writer.dart';
import 'package:tapture/core/export/record_document_text.dart';
import 'package:tapture/core/export/word_writer.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/file_validation.dart';
import 'package:tapture/core/files/file_writer.dart'
    show discardUnpublishedFile;
import 'package:tapture/core/import/import.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../domain/template_json.dart';
import '../domain/template_row.dart';

/// Validates external template documents before decoding or workbook mapping.
abstract final class TemplateDocumentImport {
  static const List<String> extensions = <String>[
    'json',
    'csv',
    'xlsx',
    'docx',
    'txt',
  ];

  /// Word/text documents contain explicit `{{field_key}}` placeholders.
  static bool isOutput(PickedDocument document) =>
      document.name.toLowerCase().endsWith('.docx') ||
      document.name.toLowerCase().endsWith('.txt');

  static bool isJson(PickedDocument document) =>
      document.name.toLowerCase().endsWith('.json');

  static Future<Result<void>> validate(PickedDocument document) async {
    final String name = document.name.toLowerCase();
    if (!extensions.any((String extension) => name.endsWith('.$extension'))) {
      return FailureResult<void>(_invalidFailure);
    }
    final Result<ImportKind> checked = await FileValidation().validateDocument(
      document,
      allowed: const <ImportKind>{ImportKind.spreadsheet, ImportKind.document},
    );
    return switch (checked) {
      FailureResult<ImportKind>(:final Failure failure) => FailureResult<void>(
        failure,
      ),
      Success<ImportKind>() => const Success<void>(null),
    };
  }

  /// Derives a record schema from explicit placeholders without altering the source.
  static Future<Result<TemplateDef>> output(
    PickedDocument document, {
    required String projectId,
    CancellationToken? cancel,
  }) async {
    final Result<void> checked = await validate(document);
    if (checked case FailureResult<void>(:final Failure failure)) {
      return FailureResult<TemplateDef>(failure);
    }
    if (!isOutput(document)) return FailureResult<TemplateDef>(_invalidFailure);
    final Result<Uint8List> read = await readPickedDocument(document);
    return switch (read) {
      FailureResult<Uint8List>(:final Failure failure) =>
        FailureResult<TemplateDef>(failure),
      Success<Uint8List>(:final Uint8List value) => runIsolate(_decodeOutput, (
        bytes: value,
        name: document.name,
        projectId: projectId,
      ), cancel: cancel),
    };
  }

  static Future<Result<TemplateDef>> json(
    PickedDocument document, {
    required String projectId,
    CancellationToken? cancel,
  }) async {
    final Result<void> checked = await validate(document);
    if (checked case FailureResult<void>(:final Failure failure)) {
      return FailureResult<TemplateDef>(failure);
    }
    if (!isJson(document)) return FailureResult<TemplateDef>(_invalidFailure);
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<TemplateDef>(CancelledFailure());
    }
    final Result<Uint8List> read = await readPickedDocument(document);
    return switch (read) {
      FailureResult<Uint8List>(:final Failure failure) =>
        FailureResult<TemplateDef>(failure),
      Success<Uint8List>(:final Uint8List value) => await runIsolate(
        _decodeBytes,
        (bytes: value, projectId: projectId),
        cancel: cancel,
      ),
    };
  }

  static Future<Result<TemplateDef>> payload(
    Object raw, {
    required String projectId,
    CancellationToken? cancel,
  }) => runIsolate(_decodePayload, (
    raw: raw,
    projectId: projectId,
  ), cancel: cancel);

  static Future<Result<WorkbookSnapshot>> workbook(
    PickedDocument document, {
    CancellationToken? cancel,
  }) async {
    final Result<void> checked = await validate(document);
    if (checked case FailureResult<void>(:final Failure failure)) {
      return FailureResult<WorkbookSnapshot>(failure);
    }
    return switch (document) {
      PickedFile(:final file) => WorkbookReader.open(file.path, cancel: cancel),
      PickedBytes(:final Uint8List bytes) => WorkbookReader.openBytes(
        bytes,
        sourceName: document.name,
        cancel: cancel,
      ),
    };
  }

  /// Only the phone picker's disposable copy belongs to this import.
  static Future<void> discard(PickedDocument? document) async {
    if (document case PickedFile(:final file, isCopy: true)) {
      await Result.captureAsync(() => discardUnpublishedFile(file));
    }
  }
}

TemplateDef _decodeBytes(({Uint8List bytes, String projectId}) input) {
  final String text;
  try {
    text = utf8.decode(input.bytes);
  } on FormatException {
    throw _invalidFailure;
  }
  return _decodePayload((raw: text, projectId: input.projectId));
}

TemplateDef _decodePayload(({Object raw, String projectId}) input) =>
    switch (TemplateJson.decode(input.raw, projectId: input.projectId)) {
      Success<TemplateDef>(:final TemplateDef value) => value,
      FailureResult<TemplateDef>(failure: final Failure decodeFailure) =>
        throw decodeFailure,
    };

final ValidationFailure _invalidFailure = ValidationFailure(
  localizedMessage: Copy.messages.templatesImportInvalid,
  localizedRecovery: Copy.messages.templatesImportInvalidRecovery,
);

TemplateDef _decodeOutput(
  ({Uint8List bytes, String name, String projectId}) input,
) {
  final Set<String> placeholders;
  try {
    placeholders = input.name.toLowerCase().endsWith('.docx')
        ? WordWriter.fields(input.bytes)
        : RecordDocumentText.placeholder
              .allMatches(PlainTextWriter.decode(input.bytes))
              .map((match) => match.group(1)!)
              .toSet();
  } on Object {
    throw Failure.from(OoxmlPackage.invalid());
  }
  placeholders.removeAll(const <String>{
    'record_number',
    'template_name',
    'context_path',
    'operator_name',
  });
  if (placeholders.isEmpty) throw _invalidFailure;
  final String name = input.name.substring(0, input.name.lastIndexOf('.'));
  return TemplateDef(
    id: '',
    templateKey: '',
    name: name,
    version: 1,
    projectId: input.projectId,
    source: 'imported',
    fields: <FieldDef>[
      for (final String key in placeholders)
        FieldDef(
          fieldKey: key,
          label: key.replaceAll('_', ' '),
          type: FieldType.text,
        ),
    ],
    identityFieldKeys: const <String>[],
    rows: const <TemplateRow>[],
  );
}
