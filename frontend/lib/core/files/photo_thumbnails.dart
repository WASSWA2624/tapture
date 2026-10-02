import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/files/thumbnail_cache.dart';

/// Absolute path of a stored photo's cached thumbnail, for lists that must
/// never decode the original (FE-PERF-04).
abstract interface class PhotoThumbnails {
  /// Resolves photos under [storageRoot] and caches through [cache], which
  /// defaults to a [ThumbnailCache] over the same root.
  factory PhotoThumbnails({
    required StorageRoot storageRoot,
    ThumbnailCache? cache,
    FileReader? files,
    FileWriter? writer,
  }) {
    return _PhotoThumbnails(
      storageRoot: storageRoot,
      cache:
          cache ??
          ThumbnailCache(
            storageRoot: storageRoot,
            files: files,
            writer: writer,
          ),
    );
  }

  /// Serves [paths] and, for the browser path, [bytes], both keyed by
  /// storage path, and fails for any other photo.
  factory PhotoThumbnails.fake(
    Map<String, String> paths, {
    Map<String, Uint8List> bytes,
  }) = _FakePhotoThumbnails;

  /// The cached thumbnail at [edge] for the photo whose file is
  /// [storagePath], relative to the storage root. Generates it on a miss.
  Future<Result<String>> pathFor({
    required String sha256,
    required String storagePath,
    required int edge,
  });

  /// A browser-safe cached thumbnail, encoded at [edge] rather than full size.
  Future<Result<Uint8List>> bytesFor({
    required String sha256,
    required String storagePath,
    required int edge,
  });
}

/// The process-wide [PhotoThumbnails]. Tests override it with
/// [PhotoThumbnails.fake].
final Provider<PhotoThumbnails> photoThumbnailsProvider =
    Provider<PhotoThumbnails>((Ref ref) {
      return PhotoThumbnails(storageRoot: ref.watch(storageRootProvider));
    });

/// Whether stored thumbnails are drawn from bytes ([PhotoThumbnails.bytesFor])
/// rather than cached files: true in a browser, which has no file to open.
/// Tests override it to draw the browser path.
final Provider<bool> thumbnailsFromBytesProvider = Provider<bool>(
  (Ref _) => kIsWeb,
);

final StorageFailure _unreadable = StorageFailure(
  localizedMessage: Copy.messages.photoUnreadable,
  localizedRecovery: Copy.messages.photoUnreadableRecovery,
);

final class _PhotoThumbnails implements PhotoThumbnails {
  _PhotoThumbnails({required this._storageRoot, required this._cache});

  final StorageRoot _storageRoot;
  final ThumbnailCache _cache;

  @override
  Future<Result<Uint8List>> bytesFor({
    required String sha256,
    required String storagePath,
    required int edge,
  }) => _cache.thumbnailBytes(sha256, storagePath, edge: edge);

  @override
  Future<Result<String>> pathFor({
    required String sha256,
    required String storagePath,
    required int edge,
  }) async {
    final Result<Directory> root = await _storageRoot.resolve();
    switch (root) {
      case FailureResult<Directory>(:final Failure failure):
        return FailureResult<String>(failure);
      case Success<Directory>(:final Directory value):
        final File source = File('${value.path}/$storagePath');
        if (!await source.exists()) {
          return FailureResult<String>(_unreadable);
        }
        final Result<File> thumb = await _cache.thumbnail(
          sha256,
          source.path,
          edge: edge,
        );
        return thumb.map((File file) => file.path);
    }
  }
}

final class _FakePhotoThumbnails implements PhotoThumbnails {
  _FakePhotoThumbnails(
    this._paths, {
    this._bytes = const <String, Uint8List>{},
  });

  final Map<String, String> _paths;
  final Map<String, Uint8List> _bytes;

  @override
  Future<Result<Uint8List>> bytesFor({
    required String sha256,
    required String storagePath,
    required int edge,
  }) async {
    final Uint8List? bytes = _bytes[storagePath];
    if (bytes == null) {
      return FailureResult<Uint8List>(_unreadable);
    }
    return Success<Uint8List>(bytes);
  }

  @override
  Future<Result<String>> pathFor({
    required String sha256,
    required String storagePath,
    required int edge,
  }) async {
    final String? path = _paths[storagePath];
    if (path == null) {
      return FailureResult<String>(_unreadable);
    }
    return Success<String>(path);
  }
}
