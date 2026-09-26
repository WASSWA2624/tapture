import 'dart:io';

import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'file_writer_stub.dart'
    if (dart.library.io) 'file_writer_io.dart'
    if (dart.library.js_interop) 'file_writer_web.dart'
    as platform;

part 'written_file.dart';

/// Removes a file that was never recorded. A missing file is left alone.
Future<void> discardUnpublishedFile(File file) async {
  if (await file.exists()) {
    await file.delete();
  }
}

/// Streams bytes into the storage tree, hashes them in the same pass, and
/// publishes the file only once it is whole.
///
/// On device each file is written under the storage root through a `.part`
/// file and a rename. In a browser, which has no file system, each file is
/// an entry in the IndexedDB store `AppConstants.projectFiles.storeName`,
/// keyed by the same relative path (`BlobFileWriter`). Callers never reach
/// either directly (FE-STR-11).
abstract interface class FileWriter {
  /// The writer for this platform. On device it writes under [storageRoot];
  /// tests pass [StorageRoot.fake] and the failure seams so a suite can
  /// interrupt a write without filling a disk. A browser keeps its files in
  /// IndexedDB and ignores both.
  factory FileWriter({
    required StorageRoot storageRoot,
    int? failAfterBytes,
    bool fullDisk = false,
    bool permissionDenied = false,
    bool vanishedParent = false,
  }) {
    return platform.openFileWriter(
      storageRoot: storageRoot,
      failAfterBytes: failAfterBytes,
      fullDisk: fullDisk,
      permissionDenied: permissionDenied,
      vanishedParent: vanishedParent,
    );
  }

  /// Streams [bytes] to [relativePath] under the storage root, replacing
  /// what is there. Completes once the file is durable (FE-STATE-07).
  Future<Result<WrittenFile>> write(
    Stream<List<int>> bytes,
    String relativePath,
  );

  /// Copies [source] through the same atomic write as [write].
  Future<Result<WrittenFile>> copyIn(File source, String relativePath);
}
