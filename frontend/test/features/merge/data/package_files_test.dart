import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/features/merge/data/package_files.dart';

void main() {
  final Uint8List bytes = Uint8List.fromList(utf8.encode('a photo'));

  test('files kept in a store are written, found and removed', () async {
    final PackageFiles files = PackageFiles.blobs(BlobStore.memory());
    const String path = 'projects/pumps/photos/a.jpg';

    expect(await files.exists(path), isFalse);
    final WrittenFile written = switch (await files.write(path, bytes)) {
      Success<WrittenFile>(:final WrittenFile value) => value,
      FailureResult<WrittenFile>(:final Failure failure) => throw TestFailure(
        failure.message,
      ),
    };
    expect(written.sha256, crypto.sha256.convert(bytes).toString());
    expect(await files.exists(path), isTrue);

    await files.removeFolder('projects/pumps');
    expect(await files.exists(path), isTrue, reason: 'a store has no folders');
    await files.remove(path);
    expect(await files.exists(path), isFalse);
    await files.remove(path);
  });

  test('a failing writer reports the failure', () async {
    final PackageFiles files = PackageFiles.blobs(
      BlobStore.memory(),
      writer: const _Refusing(),
    );
    expect(
      await files.write('projects/pumps/a.jpg', bytes),
      isA<FailureResult<WrittenFile>>(),
    );
    expect(await files.exists('projects/pumps/a.jpg'), isFalse);
  });
}

final class _Refusing implements FileWriter {
  const _Refusing();

  @override
  Future<Result<WrittenFile>> write(
    Stream<List<int>> bytes,
    String relativePath,
  ) async {
    return const FailureResult<WrittenFile>(
      StorageFailure(message: 'full', recoveryAction: 'free space'),
    );
  }

  @override
  Future<Result<WrittenFile>> copyIn(File source, String relativePath) {
    return write(const Stream<List<int>>.empty(), relativePath);
  }
}
