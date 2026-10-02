import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/path_sanitizer.dart';

import 'file_writer.dart';

/// A [FileWriter] over any [BlobStore]: each file is one entry keyed by its
/// path under the storage root. It is how a browser, which has no file
/// system, keeps project files; tests run it over [BlobStore.memory].
///
/// Like the device writer it stores exactly the path it is given and
/// replaces what is there, so an original is written once under its own id
/// and markup saves beside it (FE-SEC-08).
final class BlobFileWriter implements FileWriter {
  /// Writes into [store]. [onFirstWrite] runs once, before this writer's
  /// first write; a browser asks there for persistent storage.
  BlobFileWriter(this._store, {this._onFirstWrite});

  final BlobStore _store;
  void Function()? _onFirstWrite;

  @override
  Future<Result<WrittenFile>> write(
    Stream<List<int>> bytes,
    String relativePath,
  ) async {
    final String relative;
    try {
      relative = safeRelativePath(relativePath);
    } on Failure catch (failure) {
      return FailureResult<WrittenFile>(
        StorageFailure(
          message: failure.message,
          localizedMessage: failure.localizedMessage,
          recoveryAction:
              failure.recoveryAction ??
              'Save the file under the project folder and try again.',
          localizedRecovery: failure.localizedRecovery,
        ),
      );
    }
    final void Function()? first = _onFirstWrite;
    _onFirstWrite = null;
    first?.call();
    final BytesBuilder buffer = BytesBuilder(copy: false);
    final _DigestSink digest = _DigestSink();
    final ByteConversionSink hashing = sha256.startChunkedConversion(digest);
    try {
      await for (final List<int> chunk in bytes) {
        buffer.add(chunk);
        hashing.add(chunk);
      }
    } on Object {
      return FailureResult<WrittenFile>(_writeFailure(relative));
    }
    hashing.close();
    final Uint8List stored = buffer.takeBytes();
    // Completes only once the store reports the write durable
    // (FE-STATE-07).
    final Result<void> written = await _store.write(relative, stored);
    return switch (written) {
      FailureResult<void>() => FailureResult<WrittenFile>(
        _writeFailure(relative),
      ),
      Success<void>() => Success<WrittenFile>(
        WrittenFile(
          relativePath: relative,
          sha256: digest.value.toString(),
          byteLength: stored.length,
        ),
      ),
    };
  }

  /// Browser imports arrive as bytes through [write]; there is no file on
  /// disk to copy.
  @override
  Future<Result<WrittenFile>> copyIn(File source, String relativePath) async {
    return FailureResult<WrittenFile>(
      StorageFailure(
        localizedMessage: Copy.messages.failureTaptureCannotCopyAFileFromThis,
        localizedRecovery: Copy.messages.failureAddTheFileAgainFromTaptureThen,
      ),
    );
  }
}

StorageFailure _writeFailure(String path) {
  return StorageFailure(
    localizedMessage: Copy.messages.failureTaptureCouldNotWriteToValue(
      (path).toString(),
    ),
    localizedRecovery: Copy.messages.failureFreeUpSpaceOrExportAProject,
  );
}

final class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}
