import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
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
  final Set<String> _recoveredDirectories = <String>{};

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
          if (!await dest.parent.exists() &&
              !await _createParent(dest.parent)) {
            return FailureResult<WrittenFile>(_missingParent(dest.parent.path));
          }
          return await _storageRoot.withWriteLock(
            dest.parent.path,
            () => _publish(bytes, dest, relative),
          );
      }
    } on Failure catch (failure) {
      return FailureResult<WrittenFile>(failure);
    } on Object catch (error) {
      return FailureResult<WrittenFile>(_ioFailure(error, relativePath));
    }
  }

  Future<Result<WrittenFile>> _publish(
    Stream<List<int>> bytes,
    File dest,
    String relative,
  ) async {
    File? part;
    try {
      if (!_recoveredDirectories.contains(dest.parent.path)) {
        await _sweepParts(dest.parent);
        _recoveredDirectories.add(dest.parent.path);
      }
      part = File('${dest.path}$_partSuffix');
      final _HashedWrite hashed = await _streamToPart(
        bytes,
        part,
        failAfterBytes: _failAfterBytes,
      );
      // Rename replaces a completed target atomically; deleting it first
      // would lose the previous file if publication failed.
      await part.rename(dest.path);
      part = null;
      return Success<WrittenFile>(
        WrittenFile(
          relativePath: relative,
          sha256: hashed.sha256,
          byteLength: hashed.byteLength,
        ),
      );
    } finally {
      await _discard(part);
    }
  }
}

Stream<List<int>> _chunksOf(File source) async* {
  final RandomAccessFile handle = await source.open();
  final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes);
  try {
    while (true) {
      final int n = await handle.readInto(buffer);
      if (n == 0) {
        break;
      }
      yield Uint8List.sublistView(buffer, 0, n);
    }
  } finally {
    await handle.close();
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
        final Uint8List slice = Uint8List.sublistView(data, offset, end);
        if (failAfterBytes != null && total + slice.length > failAfterBytes) {
          final int remaining = failAfterBytes - total;
          if (remaining > 0) {
            await handle.writeFrom(slice, 0, remaining);
            sink.add(Uint8List.sublistView(slice, 0, remaining));
            total += remaining;
          }
          throw const _WriteInterrupted();
        }
        await handle.writeFrom(slice);
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
    return StorageFailure(
      localizedMessage: Copy.messages.failureThePhotoCouldNotBeSavedOn,
      localizedRecovery: Copy.messages.failureFreeUpSpaceOrExportAProject,
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
    localizedMessage: Copy.messages.failureTaptureCouldNotWriteToValue(
      (path).toString(),
    ),
    localizedRecovery: Copy.messages.failureFreeUpSpaceOrExportAProject,
  );
}

StorageFailure _fullDiskFailure(String path) {
  return StorageFailure(
    localizedMessage: Copy.messages.failureThereIsNotEnoughSpaceToSave(
      (path).toString(),
    ),
    localizedRecovery: Copy.messages.failureFreeUpSpaceOrExportAProject,
  );
}

StorageFailure _permissionFailure(String path) {
  return StorageFailure(
    localizedMessage: Copy.messages.failureTaptureCouldNotWriteToValue(
      (path).toString(),
    ),
    localizedRecovery: Copy.messages.failureAllowStorageAccessThenTryAgain,
  );
}

StorageFailure _missingParent(String path) {
  return StorageFailure(
    localizedMessage: Copy.messages.failureTaptureCouldNotFindValue(
      (path).toString(),
    ),
    localizedRecovery:
        Copy.messages.failureRecreateTheProjectFolderThenTryAgain,
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
