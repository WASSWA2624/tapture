import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'file_writer.dart';

/// Suffix of an in-flight write. Never the name the app reads.
const String _partSuffix = '.part';

/// The writer over the device's file system, under [storageRoot]. The
/// flags are the failure seams a suite uses to interrupt a write without
/// filling a disk (FE-TEST-10).
FileWriter openFileWriter({
  required StorageRoot storageRoot,
  int? failAfterBytes,
  bool fullDisk = false,
  bool permissionDenied = false,
  bool vanishedParent = false,
}) {
  return _FileWriter(
    storageRoot: storageRoot,
    failAfterBytes: failAfterBytes,
    fullDisk: fullDisk,
    permissionDenied: permissionDenied,
    vanishedParent: vanishedParent,
  );
}

final class _FileWriter implements FileWriter {
  _FileWriter({
    required this._storageRoot,
    required this._failAfterBytes,
    required this._fullDisk,
    required this._permissionDenied,
    required this._vanishedParent,
  });

  final StorageRoot _storageRoot;
  final int? _failAfterBytes;
  final bool _fullDisk;
  final bool _permissionDenied;
  final bool _vanishedParent;

  @override
  Future<Result<WrittenFile>> write(
    Stream<List<int>> bytes,
    String relativePath,
  ) {
    return _write(bytes, relativePath);
  }

  @override
  Future<Result<WrittenFile>> copyIn(File source, String relativePath) {
    return _write(_chunksOf(source), relativePath);
  }

  Future<Result<WrittenFile>> _write(
    Stream<List<int>> bytes,
    String relativePath,
  ) async {
    File? part;
    try {
      final String relative = safeRelativePath(relativePath);
      final Result<Directory> root = await _storageRoot.resolve();
      switch (root) {
        case FailureResult<Directory>(:final failure):
          return FailureResult<WrittenFile>(failure);
        case Success<Directory>(:final value):
          final String destPath = '${value.path}/$relative';
          if (_fullDisk) {
            return FailureResult<WrittenFile>(_fullDiskFailure(relative));
          }
          if (_permissionDenied) {
            return FailureResult<WrittenFile>(_permissionFailure(destPath));
          }
          final File dest = File(destPath);
          if (_vanishedParent) {
            return FailureResult<WrittenFile>(_missingParent(dest.parent.path));
          }
          if (!dest.parent.existsSync() && !await _createParent(dest.parent)) {
            return FailureResult<WrittenFile>(_missingParent(dest.parent.path));
          }
          await _sweepParts(dest.parent);
          part = File('$destPath$_partSuffix');
          if (part.existsSync()) {
            await part.delete();
          }
          final _HashedWrite hashed = await _streamToPart(
            bytes,
            part,
            failAfterBytes: _failAfterBytes,
          );
          if (dest.existsSync()) {
            await dest.delete();
          }
          await part.rename(destPath);
          part = null;
          return Success<WrittenFile>(
            WrittenFile(
              relativePath: relative,
              sha256: hashed.sha256,
              byteLength: hashed.byteLength,
            ),
          );
      }
    } on Failure catch (failure) {
      await _discard(part);
      return FailureResult<WrittenFile>(failure);
    } on Object catch (error) {
      await _discard(part);
      return FailureResult<WrittenFile>(_ioFailure(error, relativePath));
    }
  }
}

Stream<List<int>> _chunksOf(File source) async* {
  final RandomAccessFile handle = await source.open();
  final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes);
  try {
    while (true) {
      final int n = handle.readIntoSync(buffer);
      if (n == 0) {
        break;
      }
      yield Uint8List.fromList(buffer.sublist(0, n));
    }
  } finally {
    handle.closeSync();
  }
}

Future<bool> _createParent(Directory parent) async {
  try {
    await parent.create(recursive: true);
    return true;
  } on Object {
    return false;
  }
}

Future<void> _sweepParts(Directory directory) async {
  if (!directory.existsSync()) {
    return;
  }
  await for (final FileSystemEntity entity in directory.list()) {
    if (entity is File && entity.path.endsWith(_partSuffix)) {
      try {
        await entity.delete();
      } on Object {
        // A leftover `.part` is not user data; the next write retries.
      }
    }
  }
}

Future<void> _discard(File? part) async {
  if (part == null || !part.existsSync()) {
    return;
  }
  try {
    await part.delete();
  } on Object {
    // Swept on the next write to this directory.
  }
}

Future<_HashedWrite> _streamToPart(
  Stream<List<int>> bytes,
  File part, {
  int? failAfterBytes,
}) async {
  final RandomAccessFile handle = await part.open(mode: FileMode.write);
  final _HashSink output = _HashSink();
  final ByteConversionSink sink = sha256.startChunkedConversion(output);
  final int chunkBytes = AppConstants.hashing.chunkBytes;
  var total = 0;
  try {
    await for (final List<int> chunk in bytes) {
      final Uint8List data = chunk is Uint8List
          ? chunk
          : Uint8List.fromList(chunk);
      for (int offset = 0; offset < data.length; offset += chunkBytes) {
        final int end = offset + chunkBytes < data.length
            ? offset + chunkBytes
            : data.length;
        final Uint8List slice = data.sublist(offset, end);
        if (failAfterBytes != null && total + slice.length > failAfterBytes) {
          final int remaining = failAfterBytes - total;
          if (remaining > 0) {
            handle.writeFromSync(slice, 0, remaining);
            sink.add(slice.sublist(0, remaining));
            total += remaining;
          }
          throw const _WriteInterrupted();
        }
        handle.writeFromSync(slice);
        sink.add(slice);
        total += slice.length;
      }
    }
    sink.close();
    await handle.flush();
  } finally {
    await handle.close();
  }
  IsolateRunner.reportProgress(1);
  return _HashedWrite(sha256: output.digest.toString(), byteLength: total);
}

StorageFailure _ioFailure(Object error, String path) {
  if (error is _WriteInterrupted) {
    return const StorageFailure(
      message: 'The photo could not be saved on this device.',
      recoveryAction: 'Free up space or export a project, then try again.',
    );
  }
  if (error is FileSystemException) {
    final int? code = error.osError?.errorCode;
    if (code == 28 || code == 112) {
      return _fullDiskFailure(path);
    }
    if (code == 13 || code == 5) {
      return _permissionFailure(path);
    }
    if (code == 2 || code == 3) {
      return _missingParent(path);
    }
  }
  return StorageFailure(
    message: 'Tapture could not write to $path.',
    recoveryAction: 'Free up space or export a project, then try again.',
  );
}

StorageFailure _fullDiskFailure(String path) {
  return StorageFailure(
    message: 'There is not enough space to save $path.',
    recoveryAction: 'Free up space or export a project, then try again.',
  );
}

StorageFailure _permissionFailure(String path) {
  return StorageFailure(
    message: 'Tapture could not write to $path.',
    recoveryAction: 'Allow storage access, then try again.',
  );
}

StorageFailure _missingParent(String path) {
  return StorageFailure(
    message: 'Tapture could not find $path.',
    recoveryAction: 'Recreate the project folder, then try again.',
  );
}

final class _HashedWrite {
  const _HashedWrite({required this.sha256, required this.byteLength});

  final String sha256;
  final int byteLength;
}

final class _HashSink implements Sink<Digest> {
  late final Digest digest;

  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}

final class _WriteInterrupted implements Exception {
  const _WriteInterrupted();
}
