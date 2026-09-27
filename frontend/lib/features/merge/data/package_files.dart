import 'dart:typed_data';

import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'package_files_stub.dart'
    if (dart.library.io) 'package_files_io.dart'
    if (dart.library.js_interop) 'package_files_web.dart'
    as platform;

/// Where an imported package's files land, and how an unfinished import is
/// undone (task 076, W19 and W21). Paths are relative to the storage root.
///
/// On a device the files go under the storage root; in a browser, which has
/// no file system, into the project file store.
abstract interface class PackageFiles {
  /// The files of this platform. Tests pass [writer] to fail a copy part way.
  factory PackageFiles({required StorageRoot storageRoot, FileWriter? writer}) {
    return platform.openPackageFiles(storageRoot: storageRoot, writer: writer);
  }

  /// Files kept in [store], as a browser keeps them and suites do.
  factory PackageFiles.blobs(BlobStore store, {FileWriter? writer}) {
    return _BlobPackageFiles(store, writer ?? BlobFileWriter(store));
  }

  /// Writes [bytes] to [relativePath], completing once they are durable.
  Future<Result<WrittenFile>> write(String relativePath, Uint8List bytes);

  /// Whether something is stored at [relativePath].
  Future<bool> exists(String relativePath);

  /// Removes [relativePath]. A missing file is left alone.
  Future<void> remove(String relativePath);

  /// Removes the folder [relativePath] with everything in it, where folders
  /// exist. A browser has none; its files are removed one by one.
  Future<void> removeFolder(String relativePath);
}

final class _BlobPackageFiles implements PackageFiles {
  _BlobPackageFiles(this._store, this._writer);

  final BlobStore _store;
  final FileWriter _writer;

  @override
  Future<Result<WrittenFile>> write(String relativePath, Uint8List bytes) {
    return _writer.write(Stream<List<int>>.value(bytes), relativePath);
  }

  @override
  Future<bool> exists(String relativePath) async {
    final Result<Uint8List?> read = await _store.read(relativePath);
    return switch (read) {
      Success<Uint8List?>(:final Uint8List? value) => value != null,
      FailureResult<Uint8List?>() => false,
    };
  }

  @override
  Future<void> remove(String relativePath) async {
    await _store.remove(relativePath);
  }

  @override
  Future<void> removeFolder(String relativePath) async {}
}
