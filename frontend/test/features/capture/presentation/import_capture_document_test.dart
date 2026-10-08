import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart' as platform;
import 'package:tapture/features/capture/presentation/import_capture_document.dart';

import '../../../support/capture_documents.dart';

void main() {
  for (final MapEntry<String, Uint8List> original
      in captureDocumentOriginals().entries) {
    test(
      'intake validates and preserves the original ${original.key}',
      () async {
        ({Uint8List bytes, String filename})? received;
        final Result<void> result = await ImportCaptureDocument.run(
          picker: platform.DocumentPicker.fake(
            document: platform.PickedBytes(original.value, original.key),
          ),
          onImported: (Uint8List bytes, String filename) {
            received = (bytes: bytes, filename: filename);
          },
        );
        expect(result, isA<Success<void>>());
        expect(received?.filename, original.key);
        expect(received?.bytes, orderedEquals(original.value));
      },
    );
  }

  test(
    'platform and byte-picker cancellation remain typed and import nothing',
    () async {
      int imported = 0;
      for (final bool bytePicker in <bool>[false, true]) {
        final Result<void> result = await ImportCaptureDocument.run(
          picker: const platform.DocumentPicker.fake(),
          pickBytes: bytePicker ? () async => null : null,
          onImported: (Uint8List _, String _) => imported++,
        );
        expect(
          (result as FailureResult<void>).failure,
          isA<CancelledFailure>(),
        );
      }
      expect(imported, 0);
    },
  );

  test('extension size and forged magic fail before durable intake', () async {
    int imported = 0;
    for (final ({Uint8List bytes, String filename}) rejected
        in <({Uint8List bytes, String filename})>[
          (
            bytes: Uint8List.fromList('%PDF-1.4'.codeUnits),
            filename: 'wrong.exe',
          ),
          (bytes: Uint8List(64), filename: 'large.pdf'),
          (
            bytes: Uint8List.fromList('forged'.codeUnits),
            filename: 'wrong.pdf',
          ),
        ]) {
      final Result<void> result = await ImportCaptureDocument.run(
        picker: const platform.DocumentPicker.fake(),
        pickBytes: () async => rejected,
        maxBytes: 32,
        onImported: (Uint8List _, String _) => imported++,
      );
      expect(result, isA<FailureResult<void>>());
    }
    expect(imported, 0);
  });

  test(
    'picker and durable-intake failure preserve the original typed failure',
    () async {
      const StorageFailure refused = StorageFailure(message: 'Device is full');
      final Result<void> picking = await ImportCaptureDocument.run(
        picker: const platform.DocumentPicker.fake(failure: refused),
        onImported: (Uint8List _, String _) =>
            fail('Refused pick must not import'),
      );
      expect((picking as FailureResult<void>).failure, same(refused));
      final Uint8List bytes = captureDocumentOriginals().values.first;
      final String name = captureDocumentOriginals().keys.first;
      final Result<void> storing = await ImportCaptureDocument.run(
        picker: platform.DocumentPicker.fake(
          document: platform.PickedBytes(bytes, name),
        ),
        onImported: (Uint8List original, String originalName) {
          expect(original, orderedEquals(bytes));
          expect(originalName, name);
          throw refused;
        },
      );
      expect((storing as FailureResult<void>).failure, same(refused));
      expect(bytes, orderedEquals(captureDocumentOriginals()[name]!));
    },
  );
}
