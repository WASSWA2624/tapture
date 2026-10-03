import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_validation.dart';
import 'package:tapture/core/files/picked_document.dart';

/// Original document formats supported by the shared import gate.
enum CaptureDocumentFormat {
  /// A PDF with pages that can be rendered as photo evidence.
  pdf('pdf', 'application/pdf'),

  /// UTF-8 tabular text, retained without changing delimiters or quoting.
  csv('csv', 'text/csv'),

  /// A UTF-8 JSON document, retained without normalizing its contents.
  json('json', 'application/json'),

  /// An XLSX package, retained without expanding its contents.
  xlsx(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  const CaptureDocumentFormat(this.extension, this.mimeType);

  /// Safe generated-file extension, never taken directly from a source path.
  final String extension;

  /// Source media type stored with the attachment.
  final String mimeType;

  /// Picker formats, also enforced by repositories.
  static const Set<String> extensions = <String>{'pdf', 'csv', 'json', 'xlsx'};

  /// Existing core validation kinds accepted as capture documents.
  static const Set<ImportKind> kinds = <ImportKind>{
    ImportKind.document,
    ImportKind.spreadsheet,
  };

  /// Browser picker accepts only the supported media types and extensions.
  static String get pickerMimeTypes =>
      values.map((CaptureDocumentFormat format) => format.mimeType).join(',');

  /// Validates before parsing, hashing or publishing attachment metadata.
  static Future<Result<CaptureDocumentFormat>> validate(
    Uint8List bytes,
    String filename,
  ) async {
    final Result<ImportKind> gate = await FileValidation().validateDocument(
      PickedBytes(bytes, filename),
      allowed: kinds,
    );
    if (gate case FailureResult<ImportKind>(:final Failure failure)) {
      return FailureResult<CaptureDocumentFormat>(failure);
    }
    return runIsolate(_validateStructure, (bytes: bytes, filename: filename));
  }
}

CaptureDocumentFormat _validateStructure(
  ({Uint8List bytes, String filename}) input,
) {
  final String extension = input.filename.split('.').last.toLowerCase();
  final CaptureDocumentFormat format = CaptureDocumentFormat.values.firstWhere(
    (CaptureDocumentFormat value) => value.extension == extension,
  );
  try {
    if (format == CaptureDocumentFormat.xlsx) {
      // ZipDecoder retains compressed entry data lazily. Inspect package names
      // only; no entry content is decoded and no archive is extracted.
      final Set<String> entries = ZipDecoder()
          .decodeBytes(input.bytes)
          .files
          .where((ArchiveFile entry) => entry.isFile)
          .map((ArchiveFile entry) => entry.name)
          .toSet();
      if (!entries.containsAll(const <String>{
            '[Content_Types].xml',
            'xl/workbook.xml',
            'xl/_rels/workbook.xml.rels',
          }) ||
          !entries.any(
            (String name) =>
                name.startsWith('xl/worksheets/') && name.endsWith('.xml'),
          )) {
        throw ValidationFailure(
          localizedMessage: DomainCopy.messages.captureDocumentInvalid(
            input.filename,
          ),
          localizedRecovery: DomainCopy.messages.tryAnotherFile,
        );
      }
    } else if (format != CaptureDocumentFormat.pdf) {
      final String text = utf8.decode(input.bytes);
      if (text.codeUnits.any(
        (int unit) =>
            (unit < 32 && unit != 9 && unit != 10 && unit != 13) || unit == 127,
      )) {
        throw ValidationFailure(
          localizedMessage: DomainCopy.messages.captureDocumentInvalid(
            input.filename,
          ),
          localizedRecovery: DomainCopy.messages.tryAnotherFile,
        );
      }
      if (format == CaptureDocumentFormat.json) {
        jsonDecode(text.startsWith('\uFEFF') ? text.substring(1) : text);
      }
    }
    return format;
  } on Failure {
    rethrow;
  } on Object {
    throw ValidationFailure(
      localizedMessage: DomainCopy.messages.captureDocumentInvalid(
        input.filename,
      ),
      localizedRecovery: DomainCopy.messages.tryAnotherFile,
    );
  }
}
