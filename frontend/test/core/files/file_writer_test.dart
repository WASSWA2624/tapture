import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/hash/hashing_service.dart';

void main() {
  test('an interrupted write leaves the target and .part absent', () async {
    final _Harness harness = _Harness();
    await harness.storage.resolve();
    Directory('${harness.root.path}/photos').createSync(recursive: true);
    File(
      '${harness.root.path}/photos/old.bin.part',
    ).writeAsBytesSync(const <int>[9, 9, 9]);
    final FileWriter writer = FileWriter(
      storageRoot: harness.storage,
      failAfterBytes: 4,
    );

    final Result<WrittenFile> result = await writer.write(
      Stream<List<int>>.fromIterable(<List<int>>[
        Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7, 8]),
      ]),
      'photos/shot.bin',
    );

    expect(result, isA<FailureResult<WrittenFile>>());
    expect(File('${harness.root.path}/photos/shot.bin').existsSync(), isFalse);
    expect(
      File('${harness.root.path}/photos/shot.bin.part').existsSync(),
      isFalse,
    );
    expect(
      File('${harness.root.path}/photos/old.bin.part').existsSync(),
      isFalse,
    );
  });

  test('a full disk is a StorageFailure and leaves no partial file', () async {
    final _Harness harness = _Harness();
    final FileWriter writer = FileWriter(
      storageRoot: harness.storage,
      fullDisk: true,
    );

    final Result<WrittenFile> result = await writer.write(
      Stream<List<int>>.fromIterable(<List<int>>[utf8.encode('abc')]),
      'photos/shot.bin',
    );
    final Failure? failure = result.fold((Failure value) => value, (_) => null);

    expect(failure, isA<StorageFailure>());
    expect(failure?.message.toLowerCase(), contains('space'));
    expect(failure?.recoveryAction, isNotEmpty);
    expect(File('${harness.root.path}/photos/shot.bin').existsSync(), isFalse);
    expect(
      File('${harness.root.path}/photos/shot.bin.part').existsSync(),
      isFalse,
    );
  });

  test('the returned hash matches a re-read of the stored file', () async {
    final _Harness harness = _Harness();
    final FileWriter writer = FileWriter(storageRoot: harness.storage);
    const String payload = 'abc';

    final WrittenFile written = _ok(
      await writer.write(
        Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(payload)]),
        'photos/shot.bin',
      ),
    );
    final File onDisk = File('${harness.root.path}/photos/shot.bin');
    final Result<String> rehash = await sha256OfFile(onDisk);
    final WrittenFile copied = _ok(
      await writer.copyIn(onDisk, 'photos/copy.bin'),
    );

    expect(written.relativePath, 'photos/shot.bin');
    expect(written.byteLength, payload.length);
    expect(written.sha256, sha256OfString(payload));
    expect(rehash.fold((_) => '', (String value) => value), written.sha256);
    expect(copied.sha256, written.sha256);
    expect(onDisk.readAsStringSync(), payload);
  });
}

final class _Harness {
  _Harness() {
    documents = Directory.systemTemp.createTempSync('tapture-writer-');
    addTearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });
    storage = StorageRoot.fake(documentsDirectory: documents);
  }

  late final Directory documents;
  late final StorageRoot storage;

  Directory get root => Directory('${documents.path}/Tapture');
}

WrittenFile _ok(Result<WrittenFile> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (WrittenFile value) => value);
}
