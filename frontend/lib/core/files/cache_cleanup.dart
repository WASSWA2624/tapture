import 'dart:io';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/time/clock.dart';

/// Bounds `.cache` by age then by total size. Disposable: originals are never
/// in this folder.
abstract interface class CacheCleanup {
  /// Prunes under [storageRoot]'s `.cache`. Tests pass [StorageRoot.fake]
  /// and a [FixedClock] so age is deterministic.
  factory CacheCleanup({required StorageRoot storageRoot, Clock? clock}) {
    return _CacheCleanup(
      storageRoot: storageRoot,
      clock: clock ?? const SystemClock(),
    );
  }

  /// Bytes reclaimed. [maxAge] and [maxBytes] default to
  /// [AppConstants.images].
  Future<Result<int>> prune({Duration? maxAge, int? maxBytes});
}

final class _CacheCleanup implements CacheCleanup {
  _CacheCleanup({required this._storageRoot, required this._clock});

  final StorageRoot _storageRoot;
  final Clock _clock;

  @override
  Future<Result<int>> prune({Duration? maxAge, int? maxBytes}) async {
    try {
      final Result<Directory> cache = await _storageRoot.cacheDir();
      switch (cache) {
        case FailureResult<Directory>(:final failure):
          return FailureResult<int>(failure);
        case Success<Directory>(:final value):
          return Success<int>(
            await _prune(
              value,
              maxAge: maxAge ?? AppConstants.images.cacheMaxAge,
              maxBytes: maxBytes ?? AppConstants.images.cacheMaxBytes,
            ),
          );
      }
    } on Failure catch (failure) {
      return FailureResult<int>(failure);
    } on Object {
      return const FailureResult<int>(
        StorageFailure(
          message: 'The cache could not be cleaned on this device.',
          recoveryAction: 'Free space or allow storage access, then try again.',
        ),
      );
    }
  }

  Future<int> _prune(
    Directory cache, {
    required Duration maxAge,
    required int maxBytes,
  }) async {
    final List<File> files = await _filesInside(cache);
    files.sort((File a, File b) {
      return a.statSync().modified.compareTo(b.statSync().modified);
    });
    final DateTime now = _clock.nowUtc();
    var reclaimed = 0;
    final List<File> remaining = <File>[];
    for (final File file in files) {
      final DateTime modified = file.statSync().modified.toUtc();
      if (now.difference(modified) > maxAge) {
        reclaimed += await _remove(file);
      } else {
        remaining.add(file);
      }
    }
    var total = 0;
    for (final File file in remaining) {
      total += file.statSync().size;
    }
    for (final File file in remaining) {
      if (total <= maxBytes) {
        break;
      }
      final int size = file.statSync().size;
      final int gone = await _remove(file);
      if (gone > 0) {
        total -= size;
        reclaimed += gone;
      }
    }
    return reclaimed;
  }

  Future<List<File>> _filesInside(Directory cache) async {
    final String root = _slash(cache.absolute.path);
    final List<File> files = <File>[];
    if (!cache.existsSync()) {
      return files;
    }
    await for (final FileSystemEntity entity in cache.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }
      if (!_isInside(root, entity)) {
        continue;
      }
      files.add(entity);
    }
    return files;
  }
}

Future<int> _remove(File file) async {
  if (!file.existsSync()) {
    return 0;
  }
  final int size = file.statSync().size;
  try {
    await file.delete();
    return size;
  } on Object {
    return 0;
  }
}

bool _isInside(String cacheRoot, File file) {
  final String path = _slash(file.absolute.path);
  return path == cacheRoot || path.startsWith('$cacheRoot/');
}

String _slash(String path) => path.replaceAll(r'\', '/');
