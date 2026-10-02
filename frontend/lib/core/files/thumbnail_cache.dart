import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/image_resize.dart';
import 'package:tapture/core/files/storage_root.dart';

/// Cached square-or-fit thumbnails keyed `<sha256>_<edge>` under `.cache/thumbs/`.
abstract interface class ThumbnailCache {
  /// Writes under [storageRoot]. Tests pass [StorageRoot.fake] and [decode]
  /// so a suite can count original decodes.
  factory ThumbnailCache({
    required StorageRoot storageRoot,
    FileReader? files,
    FileWriter? writer,
    Future<List<int>> Function(
      String sourcePath, {
      required int longEdge,
      required int quality,
    })?
    decode,
    int? maxConcurrent,
  }) {
    return _ThumbnailCache(
      storageRoot: storageRoot,
      files: files,
      writer: writer,
      decode: decode,
      maxConcurrent: maxConcurrent ?? AppConstants.images.concurrentDecodes,
    );
  }

  /// The cached thumbnail for [sha256] at [edge], generating it from
  /// [sourcePath] on the first miss.
  Future<Result<File>> thumbnail(
    String sha256,
    String sourcePath, {
    required int edge,
  });

  /// Encoded thumbnail read and written through the platform store, for browsers.
  Future<Result<Uint8List>> thumbnailBytes(
    String sha256,
    String storagePath, {
    required int edge,
  });
}

final class _ThumbnailCache implements ThumbnailCache {
  _ThumbnailCache({
    required StorageRoot storageRoot,
    FileReader? files,
    FileWriter? writer,
    required this._decode,
    required int maxConcurrent,
  }) : _writer = writer ?? FileWriter(storageRoot: storageRoot),
       _files = files ?? FileReader(storageRoot: storageRoot),
       _storageRoot = storageRoot,
       _gate = _DecodeGate(maxConcurrent);

  final StorageRoot _storageRoot;
  final FileWriter _writer;
  final FileReader _files;
  final _DecodeGate _gate;
  final Future<List<int>> Function(
    String sourcePath, {
    required int longEdge,
    required int quality,
  })?
  _decode;
  final Map<String, Future<Result<File>>> _inflight =
      <String, Future<Result<File>>>{};
  final Map<String, Future<Result<Uint8List>>> _pendingBytes =
      <String, Future<Result<Uint8List>>>{};

  @override
  Future<Result<Uint8List>> thumbnailBytes(
    String sha256,
    String storagePath, {
    required int edge,
  }) async {
    try {
      _assertCacheKey(sha256, edge);
      final String relative = '$_cache/$_thumbs/${sha256}_$edge';
      final Future<Result<Uint8List>>? pending = _pendingBytes[relative];
      if (pending != null) return pending;
      final Future<Result<Uint8List>> work = _cachedOrDecoded(
        relative,
        storagePath,
        edge: edge,
      );
      _pendingBytes[relative] = work;
      try {
        return await work;
      } finally {
        _pendingBytes.remove(relative);
      }
    } on Failure catch (failure) {
      return FailureResult<Uint8List>(failure);
    } on Object {
      return FailureResult<Uint8List>(FileReader.unreadable(storagePath));
    }
  }

  /// The cached bytes at [relative]; on a miss only, a decode of
  /// [storagePath] behind the decode gate, so a hit never waits on one
  /// (FE-PERF-04).
  Future<Result<Uint8List>> _cachedOrDecoded(
    String relative,
    String storagePath, {
    required int edge,
  }) async {
    final Result<Uint8List> cached = await _files.read(relative);
    if (cached is Success<Uint8List>) return cached;
    return _gate.run(() async {
      final Result<Uint8List> original = await _files.read(storagePath);
      if (original is FailureResult<Uint8List>) return original;
      final Result<Uint8List> resized = await ImageResize.fit(
        (original as Success<Uint8List>).value,
        longEdge: edge,
        quality: AppConstants.images.thumbnailQuality,
      );
      if (resized is FailureResult<Uint8List>) return resized;
      final Uint8List bytes = (resized as Success<Uint8List>).value;
      final Result<WrittenFile> written = await _writer.write(
        Stream<List<int>>.value(bytes),
        relative,
      );
      return written.map((WrittenFile _) => bytes);
    });
  }

  @override
  Future<Result<File>> thumbnail(
    String sha256,
    String sourcePath, {
    required int edge,
  }) async {
    try {
      _assertCacheKey(sha256, edge);
      final Result<Directory> root = await _storageRoot.resolve();
      switch (root) {
        case FailureResult<Directory>(:final failure):
          return FailureResult<File>(failure);
        case Success<Directory>(:final value):
          final String relative = '$_cache/$_thumbs/${sha256}_$edge';
          final File dest = File('${value.path}/$relative');
          if (await dest.exists()) {
            return Success<File>(dest);
          }
          final Future<Result<File>>? pending = _inflight[relative];
          if (pending != null) {
            return pending;
          }
          final Future<Result<File>> work = _materialise(
            dest: dest,
            relative: relative,
            sourcePath: sourcePath,
            edge: edge,
          );
          _inflight[relative] = work;
          try {
            return await work;
          } finally {
            _inflight.remove(relative);
          }
      }
    } on Failure catch (failure) {
      return FailureResult<File>(failure);
    } on Object {
      return FailureResult<File>(
        StorageFailure(
          localizedMessage:
              Copy.messages.failureTheThumbnailCouldNotBeCreatedOn,
          localizedRecovery:
              Copy.messages.failureFreeSpaceOrAllowStorageAccessThen,
        ),
      );
    }
  }

  Future<Result<File>> _materialise({
    required File dest,
    required String relative,
    required String sourcePath,
    required int edge,
  }) {
    return _gate.run(() async {
      if (await dest.exists()) {
        return Success<File>(dest);
      }
      final List<int> bytes = await _resized(
        sourcePath,
        longEdge: edge,
        quality: AppConstants.images.thumbnailQuality,
      );
      if (bytes.isEmpty) {
        return FailureResult<File>(
          StorageFailure(
            localizedMessage: Copy.messages.failureThatPhotoCouldNotBeReadAs,
            localizedRecovery:
                Copy.messages.failureCaptureThePhotoAgainThenTryAgain,
          ),
        );
      }
      final Result<WrittenFile> written = await _writer.write(
        Stream<List<int>>.fromIterable(<List<int>>[bytes]),
        relative,
      );
      switch (written) {
        case FailureResult<WrittenFile>(:final failure):
          return FailureResult<File>(failure);
        case Success<WrittenFile>():
          return Success<File>(dest);
      }
    });
  }

  Future<List<int>> _resized(
    String sourcePath, {
    required int longEdge,
    required int quality,
  }) async {
    final Future<List<int>> Function(
      String sourcePath, {
      required int longEdge,
      required int quality,
    })?
    decode = _decode;
    if (decode != null) {
      return decode(sourcePath, longEdge: longEdge, quality: quality);
    }
    final Result<Uint8List> resized = await ImageResize.fit(
      await File(sourcePath).readAsBytes(),
      longEdge: longEdge,
      quality: quality,
    );
    switch (resized) {
      case FailureResult<Uint8List>():
        return const <int>[];
      case Success<Uint8List>(:final value):
        return value;
    }
  }
}

void _assertCacheKey(String sha256, int edge) {
  if (edge <= 0) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThatThumbnailSizeIsNotValid,
      localizedRecovery: Copy.messages.failureUseTheAppThumbnailSizeAndTry,
    );
  }
  if (sha256.isEmpty ||
      sha256.contains('/') ||
      sha256.contains(r'\') ||
      sha256.contains('..')) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThatPhotoCouldNotBeCached,
      localizedRecovery: Copy.messages.failureCaptureThePhotoAgainThenTryAgain,
    );
  }
}

final class _DecodeGate {
  _DecodeGate(this._max) {
    if (_max < 1) throw ArgumentError.value(_max, 'maxConcurrent');
  }

  final int _max;
  int _inFlight = 0;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  Future<T> run<T>(Future<T> Function() body) async {
    while (_inFlight >= _max) {
      final Completer<void> waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    }
    _inFlight++;
    try {
      return await body();
    } finally {
      _inFlight--;
      if (_waiters.isNotEmpty) {
        _waiters.removeFirst().complete();
      }
    }
  }
}

const String _cache = '.cache';
const String _thumbs = 'thumbs';
