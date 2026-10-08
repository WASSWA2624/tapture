import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/capture_document_format.dart';

import '../../../support/capture_documents.dart';

void main() {
  for (final (String filename, Uint8List bytes, CaptureDocumentFormat format)
      in <(String, Uint8List, CaptureDocumentFormat)>[
        ('Original.PDF', _text('%PDF-1.7'), CaptureDocumentFormat.pdf),
        (
          'Original.CSV',
          _text('name,notes\r\nÉquipement,"first, second"\r\n'),
          CaptureDocumentFormat.csv,
        ),
        (
          'Original.JSON',
          _text('\uFEFF{"notes":["Équipement"]}'),
          CaptureDocumentFormat.json,
        ),
        (
          'Original.XLSX',
          captureDocumentOriginals().values.last,
          CaptureDocumentFormat.xlsx,
        ),
      ]) {
    test('validates $filename without changing its original bytes', () async {
      final Uint8List source = Uint8List.fromList(bytes);
      expect(
        (await CaptureDocumentFormat.validate(bytes, filename)).getOrThrow(),
        format,
      );
      expect(bytes, orderedEquals(source));
    });
  }

  for (final (String filename, Uint8List bytes) in <(String, Uint8List)>[
    ('malformed.json', _text('{broken')),
    ('binary.csv', Uint8List.fromList(<int>[0, 1, 2, 3])),
    ('binary.json', Uint8List.fromList(<int>[0xff, 0xfe, 0])),
    ('unsupported.bin', _text('plain text')),
    ('forged.csv', _text('%PDF-1.7')),
    (
      'ordinary.zip.xlsx',
      Uint8List.fromList(
        ZipEncoder().encodeBytes(
          Archive()..addFile(ArchiveFile('note.txt', 4, _text('note'))),
        ),
      ),
    ),
  ]) {
    test('rejects $filename before attachment publication', () async {
      final Result<CaptureDocumentFormat> result =
          await CaptureDocumentFormat.validate(bytes, filename);
      expect(result, isA<FailureResult<CaptureDocumentFormat>>());
      expect(
        (result as FailureResult<CaptureDocumentFormat>).failure,
        isA<ValidationFailure>(),
      );
      expect(result.failure.message, contains(filename));
    });
  }
}

Uint8List _text(String text) => Uint8List.fromList(utf8.encode(text));
