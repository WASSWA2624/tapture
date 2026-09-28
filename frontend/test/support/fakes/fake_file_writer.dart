import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';

/// An in-memory [FileWriter]: keeps every write by relative path, hashes
/// the bytes in the same pass as the device writer does, and fails on
/// demand the way a full disk would (FE-TEST-03, FE-TEST-10).
final class FakeFileWriter implements FileWriter {
  /// What landed, by relative path. A failed write leaves nothing here.
  final Map<String, Uint8List> files = <String, Uint8List>{};

  /// Every relative path a write was asked for, in call order, including
  /// the ones that failed.
  final List<String> writes = <String>[];

  /// When set, every write drains its stream and returns this instead of
  /// keeping anything.
  Failure? failure;

  @override
  Future<Result<WrittenFile>> write(
    Stream<List<int>> bytes,
    String relativePath,
  ) async {
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (final List<int> chunk in bytes) {
      builder.add(chunk);
    }
    writes.add(relativePath);
    final Failure? refused = failure;
    if (refused != null) {
      return FailureResult<WrittenFile>(refused);
    }
    final Uint8List data = builder.takeBytes();
    files[relativePath] = data;
    return Success<WrittenFile>(
      WrittenFile(
        relativePath: relativePath,
        sha256: sha256.convert(data).toString(),
        byteLength: data.length,
      ),
    );
  }

  @override
  Future<Result<WrittenFile>> copyIn(File source, String relativePath) {
    return write(source.openRead(), relativePath);
  }
}
