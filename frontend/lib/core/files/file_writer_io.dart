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
  bool crossVolume = false,
}) {
  return _FileWriter(
    storageRoot: storageRoot,
    failAfterBytes: failAfterBytes,
    fullDisk: fullDisk,
    permissionDenied: permissionDenied,
    vanishedParent: vanishedParent,
    crossVolume: crossVolume,
  );
}

final class _FileWriter implements FileWriter {
  _FileWriter({
    required this._storageRoot,
    required this._failAfterBytes,
    required this._fullDisk,
    required this._permissionDenied,
    required this._vanishedParent,
    required this._crossVolume,
  });

  final StorageRoot _storageRoot;
  final int? _failAfterBytes;
  final bool _fullDisk;
  final bool _permissionDenied;
  final bool _vanishedParent;
  final bool _crossVolume;
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

  @override
  Future<Result<WrittenFile>> adoptStaged(
    File staging,
    String relativePath,
  ) async {
    try {
      final Result<File> target = await _target(relativePath);
      if (target case FailureResult<File>(:final Failure failure)) {
        return FailureResult<WrittenFile>(failure);
      }
      final File dest = (target as Success<File>).value;
      final String relative = safeRelativePath(relativePath);
      // Hashing and the flush to disk run outside the lock: a four-hour
      // take must not hold up every other save in its folder.
      final Result<(String, int)> sealed =
          await runIsolate<String, (String, int)>(_sealStaged, staging.path);
      if (sealed case FailureResult<(String, int)>(:final Failure failure)) {
        return FailureResult<WrittenFile>(failure);
      }
      final (String hash, int length) =
          (sealed as Success<(String, int)>).value;
      final _Adopted adopted = await _storageRoot.withWriteLock(
        dest.parent.path,
        () => _rename(staging, dest, length),
      );
      switch (adopted) {
        case _Adopted.renamed:
          return Success<WrittenFile>(
            WrittenFile(
              relativePath: relative,
              sha256: hash,
              byteLength: length,
            ),
          );
        case _Adopted.targetExists:
          return FailureResult<WrittenFile>(_targetExists(relative));
        case _Adopted.changed:
          return FailureResult<WrittenFile>(_stagingChanged(relative));
        case _Adopted.otherVolume:
          // A move between volumes is a copy and a removal. The source goes
          // only once the copy is durable and hashed.
          if (await dest.exists()) {
            return FailureResult<WrittenFile>(_targetExists(relative));
          }
          final Result<WrittenFile> copied = await copyIn(staging, relative);
          if (copied is Success<WrittenFile>) {
            await discardUnpublishedFile(staging);
          }
          return copied;
      }
    } on Failure catch (failure) {
      return FailureResult<WrittenFile>(failure);
    } on Object catch (error) {
      return FailureResult<WrittenFile>(_ioFailure(error, relativePath));
    }
  }

  /// Renames [staging] to [dest] under the directory lock, unless [dest]
  /// already exists or [staging] changed after it was hashed.
  Future<_Adopted> _rename(File staging, File dest, int length) async {
    if (await dest.exists()) {
      return _Adopted.targetExists;
    }
    if (await staging.length() != length) {
      return _Adopted.changed;
    }
    if (_crossVolume) {
      return _Adopted.otherVolume;
    }
    try {
      await staging.rename(dest.path);
      return _Adopted.renamed;
    } on FileSystemException catch (error) {
      if (error.osError?.errorCode == _crossDeviceError) {
        return _Adopted.otherVolume;
      }
      rethrow;
    }
  }

  /// The file [relativePath] names under the storage root, with its parent
  /// folder created, or the failure a seam or the file system reports.
  Future<Result<File>> _target(String relativePath) async {
    final String relative = safeRelativePath(relativePath);
    final Result<Directory> root = await _storageRoot.resolve();
    switch (root) {
      case FailureResult<Directory>(:final failure):
        return FailureResult<File>(failure);
      case Success<Directory>(:final value):
        final String destPath = '${value.path}/$relative';
        if (_fullDisk) {
          return FailureResult<File>(_fullDiskFailure(relative));
        }
        if (_permissionDenied) {
          return FailureResult<File>(_permissionFailure(destPath));
        }
        final File dest = File(destPath);
        if (_vanishedParent) {
          return FailureResult<File>(_missingParent(dest.parent.path));
        }
        if (!await dest.parent.exists() && !await _createParent(dest.parent)) {
          return FailureResult<File>(_missingParent(dest.parent.path));
        }
        return Success<File>(dest);
    }
  }

  Future<Result<WrittenFile>> _write(
    Stream<List<int>> bytes,
    String relativePath,
  ) async {
    try {
      final Result<File> target = await _target(relativePath);
      switch (target) {
        case FailureResult<File>(:final failure):
          return FailureResult<WrittenFile>(failure);
        case Success<File>(value: final File dest):
          final String relative = safeRelativePath(relativePath);
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

/// What a rename under the directory lock found.
enum _Adopted { renamed, targetExists, changed, otherVolume }

/// `ERROR_NOT_SAME_DEVICE` on Windows and `EXDEV` on POSIX: the staging
/// file and the target sit on different volumes. Each code means something
/// else on the other family, so only this platform's code is matched.
final int _crossDeviceError = Platform.isWindows ? 17 : 18;

/// Forces the staged file at [path] to disk and streams its SHA-256. Runs on
/// a worker isolate, outside any directory lock.
Future<(String, int)> _sealStaged(String path) async {
  final File staged = File(path);
  final RandomAccessFile handle = await staged.open(mode: FileMode.append);
  try {
    await handle.flush();
  } finally {
    await handle.close();
  }
  final _HashSink output = _HashSink();
  final ByteConversionSink sink = sha256.startChunkedConversion(output);
  var total = 0;
  await for (final List<int> chunk in _chunksOf(staged)) {
    sink.add(chunk);
    total += chunk.length;
  }
  sink.close();
  return (output.digest.toString(), total);
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

ValidationFailure _targetExists(String path) {
  return ValidationFailure(
    localizedMessage: Copy.messages.failureTaptureCouldNotWriteToValue(
      (path).toString(),
    ),
    localizedRecovery: Copy.messages.failureFreeUpSpaceOrExportAProject,
  );
}

StorageFailure _stagingChanged(String path) {
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
