import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_media_reader.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';

void main() {
  test(
    'browser paths read the blob store without resolving native storage',
    () async {
      final AiMediaReader reader = AiMediaReader(
        files: FileReader.memory(<String, Uint8List>{
          '.cache/upload/photo': Uint8List.fromList(<int>[1, 2, 3]),
        }),
        storageRoot: StorageRoot.fake(
          documentsDirectory: Directory('unused'),
          writable: false,
        ),
        isBrowser: true,
      );
      expect(
        (await reader.read('.cache/upload/photo') as Success<Uint8List>).value,
        <int>[1, 2, 3],
      );
      expect(await reader.read('../secret'), isA<FailureResult<Uint8List>>());
    },
  );

  test('native absolute media stays inside its storage root', () async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-ai-media-',
    );
    addTearDown(() => documents.deleteSync(recursive: true));
    final StorageRoot root = StorageRoot.fake(documentsDirectory: documents);
    final Directory storage =
        (await root.resolve() as Success<Directory>).value;
    final AiMediaReader reader = AiMediaReader(
      files: FileReader.memory(<String, Uint8List>{
        'photos/a': Uint8List.fromList(<int>[8]),
      }),
      storageRoot: root,
    );
    expect(
      (await reader.read('${storage.path}/photos/a') as Success<Uint8List>)
          .value,
      <int>[8],
    );
    expect(
      await reader.read('${documents.path}/secret'),
      isA<FailureResult<Uint8List>>(),
    );
  });
}
