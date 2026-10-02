import 'dart:io';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
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
          // Walked and pruned on a worker isolate, so the launch prune never
          // stalls a frame (FE-PERF-02).
          final Result<int> pruned = await runIsolate(_pruneInIsolate, (
            path: value.path,
            maxAge: maxAge ?? AppConstants.images.cacheMaxAge,
            maxBytes: maxBytes ?? AppConstants.images.cacheMaxBytes,
            now: _clock.nowUtc(),
          ));
          return pruned.fold(
            (Failure _) => FailureResult<int>(_notCleaned),
            Success<int>.new,
          );
      }
    } on Failure catch (failure) {
      return FailureResult<int>(failure);
    } on Object {
      return FailureResult<int>(_notCleaned);
    }
  }
}

final StorageFailure _notCleaned = StorageFailure(
  localizedMessage: Copy.messages.failureTheCacheCouldNotBeCleanedOn,
  localizedRecovery: Copy.messages.failureFreeSpaceOrAllowStorageAccessThen,
);

/// Isolate entry: prunes the cache at `path` by age against `now`, then by
/// size, oldest first. Never leaves the folder.
Future<int> _pruneInIsolate(
  ({String path, Duration maxAge, int maxBytes, DateTime now}) job,
) {
  return _prune(
    Directory(job.path),
    maxAge: job.maxAge,
    maxBytes: job.maxBytes,
    now: job.now,
  );
}

Future<int> _prune(
  Directory cache, {
  required Duration maxAge,
  required int maxBytes,
  required DateTime now,
}) async {
  final List<_CacheEntry> files = await _filesInside(cache);
  files.sort((_CacheEntry a, _CacheEntry b) {
    return a.stat.modified.compareTo(b.stat.modified);
  });
  var reclaimed = 0;
  final List<_CacheEntry> remaining = <_CacheEntry>[];
  for (final _CacheEntry entry in files) {
    final DateTime modified = entry.stat.modified.toUtc();
    if (now.difference(modified) > maxAge) {
      reclaimed += await _remove(entry.file);
    } else {
      remaining.add(entry);
    }
  }
  var total = 0;
  for (final _CacheEntry entry in remaining) {
    total += entry.stat.size;
  }
  for (final _CacheEntry entry in remaining) {
    if (total <= maxBytes) {
      break;
    }
    final int size = entry.stat.size;
    final int gone = await _remove(entry.file);
    if (gone > 0) {
      total -= size;
      reclaimed += gone;
    }
  }
  return reclaimed;
}

typedef _CacheEntry = ({File file, FileStat stat});

Future<List<_CacheEntry>> _filesInside(Directory cache) async {
  final String root = _slash(cache.absolute.path);
  final List<_CacheEntry> files = <_CacheEntry>[];
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
    final FileStat stat = await entity.stat();
    if (stat.type == FileSystemEntityType.file) {
      files.add((file: entity, stat: stat));
    }
  }
  return files;
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
