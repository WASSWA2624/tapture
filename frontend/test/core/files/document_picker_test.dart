import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/document_picker_io.dart';

void main() {
  group('DocumentPicker.fake', () {
    test('hands back the document it was given', () async {
      final PickedBytes bytes = PickedBytes(
        Uint8List.fromList(<int>[1, 2, 3]),
        'site.zip',
      );
      final Result<PickedDocument> result = await DocumentPicker.fake(
        document: bytes,
      ).pick(extensions: const <String>['zip'], mimeType: 'application/zip');

      final PickedDocument picked = (result as Success<PickedDocument>).value;
      expect(picked.name, 'site.zip');
      expect(picked.byteLength, 3);
    });

    test('with nothing to give, the pick is cancelled', () async {
      final Result<PickedDocument> result = await const DocumentPicker.fake()
          .pick(extensions: const <String>['zip'], mimeType: 'application/zip');

      expect(
        (result as FailureResult<PickedDocument>).failure,
        isA<CancelledFailure>(),
      );
    });

    test('reports the failure it was given', () async {
      final Result<PickedDocument> result = await const DocumentPicker.fake(
        failure: StorageFailure(message: 'Busy.'),
      ).pick(extensions: const <String>['zip'], mimeType: 'application/zip');

      expect((result as FailureResult<PickedDocument>).failure.message, 'Busy.');
    });

    test('a picked file reports the size it was given', () {
      final PickedFile file = PickedFile(File('a.zip'), 'a.zip', 42);
      expect(file.byteLength, 42);
      expect(file.name, 'a.zip');
    });
  });

  group('desktop dialogs', () {
    test('Windows opens one file, filtered to the extensions', () {
      final List<String> arguments = windowsDocumentArguments(const <String>[
        'zip',
      ]);
      expect(arguments.take(3), <String>[
        '-NoProfile',
        '-NonInteractive',
        '-Command',
      ]);
      expect(arguments.last, contains('OpenFileDialog'));
      expect(arguments.last, contains("Filter = '*.zip|*.zip'"));
      expect(arguments.last, contains(r'Multiselect = $false'));
    });

    test('macOS chooses a file of the given types', () {
      expect(macDocumentArguments(const <String>['zip']), <String>[
        '-e',
        'POSIX path of (choose file of type {"zip"})',
      ]);
    });

    test('Linux filters the file chooser', () {
      expect(linuxDocumentArguments(const <String>['zip']), <String>[
        '--file-selection',
        '--file-filter=*.zip',
      ]);
    });
  });
}
