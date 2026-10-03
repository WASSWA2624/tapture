import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';

// Providers of the record photo viewer (task 014 step 4): the one place a
// saved photo's original is read, so lists and the record page only ever
// draw cached thumbnails (FE-PERF-04).

/// Reads saved photo originals by their path under the storage root, where
/// this platform keeps them. Tests replace it with `FileReader.memory`.
final Provider<FileReader> recordPhotoReaderProvider = Provider<FileReader>((
  Ref ref,
) {
  return FileReader(storageRoot: ref.watch(storageRootProvider));
});

/// The original bytes of the photo stored at [storagePath] (relative to the
/// storage root, as a record photo holds it), for the viewer only. A photo
/// that cannot be read fails with the photo's own words and a recovery.
/// Auto-dispose: the bytes are dropped as soon as no viewer page shows the
/// photo (FE-PERF-09), and a failure is never retried behind the viewer's
/// back.
final recordPhotoBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((Ref ref, String storagePath) async {
      final Result<Uint8List> read = await ref
          .watch(recordPhotoReaderProvider)
          .read(storagePath);
      return switch (read) {
        Success<Uint8List>(:final Uint8List value) => value,
        FailureResult<Uint8List>() => throw _unreadable,
      };
    }, retry: (int _, Object _) => null);

final StorageFailure _unreadable = StorageFailure(
  localizedMessage: Copy.messages.photoUnreadable,
  localizedRecovery: Copy.messages.photoUnreadableRecovery,
);
