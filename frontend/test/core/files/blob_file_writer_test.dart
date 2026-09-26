import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

void main() {
  test(
    'the blob writer hashes and sizes bytes as the device writer does',
    () async {
      final Directory documents = Directory.systemTemp.createTempSync(
        'tapture-blob-writer-',
      );
      addTearDown(() => documents.deleteSync(recursive: true));
      final FileWriter device = FileWriter(
        storageRoot: StorageRoot.fake(documentsDirectory: documents),
      );
      final Map<String, Uint8List> stored = <String, Uint8List>{};
      final BlobFileWriter blobs = BlobFileWriter(
        BlobStore.memory(backing: stored),
      );
      final List<List<int>> chunks = <List<int>>[
        List<int>.generate(70000, (int index) => index % 251),
        <int>[1, 2, 3],
      ];

      final WrittenFile onDevice = _ok(
        await device.write(
          Stream<List<int>>.fromIterable(chunks),
          'photos/a.jpg',
        ),
      );
      final WrittenFile inStore = _ok(
        await blobs.write(
          Stream<List<int>>.fromIterable(chunks),
          'photos/a.jpg',
        ),
      );

      expect(inStore.sha256, onDevice.sha256);
      expect(inStore.byteLength, onDevice.byteLength);
      expect(inStore.relativePath, 'photos/a.jpg');
      expect(stored['photos/a.jpg'], hasLength(70003));
    },
  );

  test('writing a path again replaces what the store held', () async {
    final Map<String, Uint8List> stored = <String, Uint8List>{};
    final BlobFileWriter writer = BlobFileWriter(
      BlobStore.memory(backing: stored),
    );

    _ok(
      await writer.write(
        Stream<List<int>>.value(<int>[1, 2, 3]),
        r'projects\site__000001\photos\p.jpg',
      ),
    );
    final WrittenFile second = _ok(
      await writer.write(
        Stream<List<int>>.value(<int>[4, 5]),
        'projects/site__000001/photos/p.jpg',
      ),
    );

    expect(stored.keys, <String>['projects/site__000001/photos/p.jpg']);
    expect(stored.values.single, <int>[4, 5]);
    expect(second.byteLength, 2);
  });

  test('a path outside the storage folder is a storage failure', () async {
    final Map<String, Uint8List> stored = <String, Uint8List>{};
    final BlobFileWriter writer = BlobFileWriter(
      BlobStore.memory(backing: stored),
    );

    for (final String path in <String>['', '/abs.jpg', 'a/../b.jpg', 'C:x']) {
      final Result<WrittenFile> result = await writer.write(
        Stream<List<int>>.value(<int>[1]),
        path,
      );
      expect(_failure(result), isA<StorageFailure>(), reason: path);
    }
    expect(stored, isEmpty);
  });

  test('a store that refuses the write is a storage failure', () async {
    final BlobFileWriter writer = BlobFileWriter(
      BlobStore.memory(failWrites: true),
    );

    final Result<WrittenFile> result = await writer.write(
      Stream<List<int>>.value(<int>[1, 2]),
      'photos/p.jpg',
    );

    final Failure? failure = _failure(result);
    expect(failure, isA<StorageFailure>());
    expect(failure?.recoveryAction, isNotEmpty);
  });

  test('a stream that fails mid-write stores nothing', () async {
    final Map<String, Uint8List> stored = <String, Uint8List>{};
    final BlobFileWriter writer = BlobFileWriter(
      BlobStore.memory(backing: stored),
    );

    final Result<WrittenFile> result = await writer.write(
      Stream<List<int>>.error(const FileSystemException('gone')),
      'photos/p.jpg',
    );

    expect(_failure(result), isA<StorageFailure>());
    expect(stored, isEmpty);
  });

  test('the first write runs the first-write hook once', () async {
    var asked = 0;
    final BlobFileWriter writer = BlobFileWriter(
      BlobStore.memory(),
      onFirstWrite: () => asked++,
    );

    _ok(await writer.write(Stream<List<int>>.value(<int>[1]), 'a/one.bin'));
    _ok(await writer.write(Stream<List<int>>.value(<int>[2]), 'a/two.bin'));

    expect(asked, 1);
  });

  test('copying a device file in is refused with a storage failure', () async {
    final BlobFileWriter writer = BlobFileWriter(BlobStore.memory());

    final Result<WrittenFile> result = await writer.copyIn(
      File('clip.wav'),
      'audio/clip.wav',
    );

    expect(_failure(result), isA<StorageFailure>());
  });
}

WrittenFile _ok(Result<WrittenFile> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (WrittenFile value) => value);
}

Failure? _failure(Result<WrittenFile> result) {
  return result.fold((Failure failure) => failure, (_) => null);
}
