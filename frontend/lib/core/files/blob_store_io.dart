import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'blob_store.dart';

/// A folder named [name] under the application support directory.
BlobStore openBlobStore(String name) {
  return folderBlobStore(() async {
    final Directory support = await getApplicationSupportDirectory();
    return Directory('${support.path}/$name');
  });
}

/// A store under the folder [folder] resolves to, created on first write.
/// The seam a suite points at a temporary folder; the app reaches it only
/// through [BlobStore.platform].
BlobStore folderBlobStore(Future<Directory> Function() folder) {
  return _FolderBlobStore(folder);
}

/// Each key is one file under a folder. Writes go through a `.part` file and
/// a rename, so a crash mid-write leaves the previous value readable.
final class _FolderBlobStore implements BlobStore {
  _FolderBlobStore(this._folder);

  final Future<Directory> Function() _folder;
  Directory? _resolved;

  @override
  Future<Result<Uint8List?>> read(String key) async {
    final Failure? invalid = keyFailure(key);
    if (invalid != null) {
      return FailureResult<Uint8List?>(invalid);
    }
    try {
      final File file = await _file(key);
      if (!file.existsSync()) {
        return const Success<Uint8List?>(null);
      }
      return Success<Uint8List?>(await file.readAsBytes());
    } on Object {
      return FailureResult<Uint8List?>(storeFailure());
    }
  }

  @override
  Future<Result<void>> write(String key, Uint8List bytes) async {
    final Failure? invalid = keyFailure(key);
    if (invalid != null) {
      return FailureResult<void>(invalid);
    }
    try {
      final File target = await _file(key);
      await target.parent.create(recursive: true);
      final File part = File('${target.path}$_partSuffix');
      await part.writeAsBytes(bytes, flush: true);
      await part.rename(target.path);
      return const Success<void>(null);
    } on Object {
      return FailureResult<void>(storeFailure());
    }
  }

  @override
  Future<Result<void>> remove(String key) async {
    final Failure? invalid = keyFailure(key);
    if (invalid != null) {
      return FailureResult<void>(invalid);
    }
    try {
      final File target = await _file(key);
      if (target.existsSync()) {
        // App-owned blobs only; evidence never reaches this store, so this
        // is not the purge job's delete (FE-SEC-08).
        await File(target.path).delete();
      }
      return const Success<void>(null);
    } on Object {
      return FailureResult<void>(storeFailure());
    }
  }

  Future<File> _file(String key) async {
    final Directory folder = _resolved ??= await _folder();
    return File('${folder.path}/$key');
  }
}

/// Suffix of an in-flight write. Never a name the store reads.
const String _partSuffix = '.part';
