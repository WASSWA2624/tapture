import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'file_writer_stub.dart'
    if (dart.library.io) 'file_writer_io.dart'
    if (dart.library.js_interop) 'file_writer_web.dart'
    as platform;

part 'written_file.dart';

/// Shared atomic-write boundary for disposable derived-file presentation.
final Provider<FileWriter> fileWriterProvider = Provider<FileWriter>(
  (Ref ref) => FileWriter(storageRoot: ref.watch(storageRootProvider)),
);

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
  /// interrupt a write without filling a disk; `crossVolume` makes
  /// [adoptStaged] treat its staging file as one on another volume. A
  /// browser keeps its files in IndexedDB and ignores both.
  factory FileWriter({
    required StorageRoot storageRoot,
    int? failAfterBytes,
    bool fullDisk = false,
    bool permissionDenied = false,
    bool vanishedParent = false,
    bool crossVolume = false,
  }) {
    return platform.openFileWriter(
      storageRoot: storageRoot,
      failAfterBytes: failAfterBytes,
      fullDisk: fullDisk,
      permissionDenied: permissionDenied,
      vanishedParent: vanishedParent,
      crossVolume: crossVolume,
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

  /// Publishes [staging], a finished file the app wrote itself, at
  /// [relativePath] by renaming it, so a long take is never copied.
  ///
  /// The file is hashed and flushed to disk before the directory lock is
  /// taken; under the lock an existing target is refused and the rename is
  /// made. A [staging] file on another volume is copied in through
  /// [copyIn] and then removed. A browser has no file to rename and
  /// returns a `ProviderFailure`.
  Future<Result<WrittenFile>> adoptStaged(File staging, String relativePath);
}
