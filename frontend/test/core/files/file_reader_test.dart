import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_file_reader.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

void main() {
  test('the device reader returns what the device writer wrote', () async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-reader-',
    );
    addTearDown(() => documents.deleteSync(recursive: true));
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);
    await FileWriter(
      storageRoot: storage,
    ).write(Stream<List<int>>.value(<int>[7, 8, 9]), 'projects/p/photos/a.jpg');

    final Result<Uint8List> read = await FileReader(
      storageRoot: storage,
    ).read('projects/p/photos/a.jpg');

    expect(_ok(read), <int>[7, 8, 9]);
  });

  test('the blob reader returns what the blob writer wrote', () async {
    final Map<String, Uint8List> stored = <String, Uint8List>{};
    await BlobFileWriter(
      BlobStore.memory(backing: stored),
    ).write(Stream<List<int>>.value(<int>[1, 2]), 'projects/p/photos/b.jpg');

    expect(
      _ok(
        await BlobFileReader(
          BlobStore.memory(backing: stored),
        ).read('projects/p/photos/b.jpg'),
      ),
      <int>[1, 2],
    );
    expect(
      _ok(await FileReader.memory(stored).read(r'projects\p\photos\b.jpg')),
      <int>[1, 2],
    );
  });

  test('a missing path is a storage failure on every reader', () async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-reader-missing-',
    );
    addTearDown(() => documents.deleteSync(recursive: true));
    final List<FileReader> readers = <FileReader>[
      FileReader(storageRoot: StorageRoot.fake(documentsDirectory: documents)),
      FileReader.memory(),
    ];

    for (final FileReader reader in readers) {
      final Failure? missing = _failure(await reader.read('photos/none.jpg'));
      expect(missing, isA<StorageFailure>());
      expect(missing?.recoveryAction, isNotEmpty);
      expect(
        _failure(await reader.read('../escape.jpg')),
        isA<StorageFailure>(),
      );
    }
  });
}

Uint8List _ok(Result<Uint8List> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (Uint8List value) => value);
}

Failure? _failure(Result<Uint8List> result) {
  return result.fold((Failure failure) => failure, (_) => null);
}
