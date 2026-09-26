import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'blob_file_reader.dart';
import 'file_reader_stub.dart'
    if (dart.library.io) 'file_reader_io.dart'
    if (dart.library.js_interop) 'file_reader_web.dart'
    as platform;

/// Reads a stored file's bytes back by its path under the storage root: the
/// read side of [FileWriter], wherever this platform keeps the files
/// (FE-STR-11).
abstract interface class FileReader {
  /// The reader for this platform: under [storageRoot] on device, and from
  /// the browser's project-file store on web, where [FileWriter] keeps them.
  factory FileReader({required StorageRoot storageRoot}) {
    return platform.openFileReader(storageRoot: storageRoot);
  }

  /// A hand-written stand-in over [files], keyed by relative path, so a
  /// suite can read back what a [BlobFileWriter] over the same map wrote
  /// (FE-STATE-10).
  factory FileReader.memory([Map<String, Uint8List>? files]) {
    return BlobFileReader(BlobStore.memory(backing: files));
  }

  /// The bytes stored at [relativePath]. A missing file, a path outside the
  /// storage root and a refused read are each a [StorageFailure].
  Future<Result<Uint8List>> read(String relativePath);

  /// The failure every reader returns when [path] cannot be read.
  static StorageFailure unreadable(String path) {
    return StorageFailure(
      message: 'Tapture could not read $path.',
      recoveryAction: 'Capture or add the file again, then try again.',
    );
  }
}
