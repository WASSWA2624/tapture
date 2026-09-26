import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

/// Cached square-or-fit thumbnails keyed `<sha256>_<edge>` under `.cache/thumbs/`.
abstract interface class ThumbnailCache {
  /// Writes under [storageRoot]. Tests pass [StorageRoot.fake] and [decode]
  /// so a suite can count original decodes.
  factory ThumbnailCache({
    required StorageRoot storageRoot,
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
}

final class _ThumbnailCache implements ThumbnailCache {
  _ThumbnailCache({
    required StorageRoot storageRoot,
    required this._decode,
    required int maxConcurrent,
  }) : _writer = FileWriter(storageRoot: storageRoot),
       _storageRoot = storageRoot,
       _gate = _DecodeGate(maxConcurrent);

  final StorageRoot _storageRoot;
  final FileWriter _writer;
  final _DecodeGate _gate;
  final Future<List<int>> Function(
    String sourcePath, {
    required int longEdge,
    required int quality,
  })?
  _decode;
  final Map<String, Future<Result<File>>> _inflight =
      <String, Future<Result<File>>>{};

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
          if (dest.existsSync()) {
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
      return const FailureResult<File>(
        StorageFailure(
          message: 'The thumbnail could not be created on this device.',
          recoveryAction: 'Free space or allow storage access, then try again.',
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
      if (dest.existsSync()) {
        return Success<File>(dest);
      }
      final List<int> bytes = await _resized(
        sourcePath,
        longEdge: edge,
        quality: AppConstants.images.thumbnailQuality,
      );
      if (bytes.isEmpty) {
        return const FailureResult<File>(
          StorageFailure(
            message: 'That photo could not be read as an image.',
            recoveryAction: 'Capture the photo again, then try again.',
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
    final Result<Uint8List> resized = await runIsolate(
      _resizeToLongEdge,
      <Object>[sourcePath, longEdge, quality],
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
    throw const ValidationFailure(
      message: 'That thumbnail size is not valid.',
      recoveryAction: 'Use the app thumbnail size and try again.',
    );
  }
  if (sha256.isEmpty ||
      sha256.contains('/') ||
      sha256.contains(r'\') ||
      sha256.contains('..')) {
    throw const ValidationFailure(
      message: 'That photo could not be cached.',
      recoveryAction: 'Capture the photo again, then try again.',
    );
  }
}

final class _DecodeGate {
  _DecodeGate(this._max);

  final int _max;
  int _inFlight = 0;
  final List<Completer<void>> _waiters = <Completer<void>>[];

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
        _waiters.removeAt(0).complete();
      }
    }
  }
}

/// Fits the photo at `job[0]` so its long edge is at most `job[1]`, as a JPEG
/// at quality `job[2]`. Pure Dart, because dart:ui cannot decode in a
/// spawned isolate.
Future<Uint8List> _resizeToLongEdge(List<Object> job) async {
  final String path = job[0] as String;
  final int longEdge = job[1] as int;
  final int quality = job[2] as int;
  if (quality < 1) {
    throw StateError('quality');
  }
  IsolateRunner.reportProgress(0);
  final Uint8List bytes = await File(path).readAsBytes();
  IsolateRunner.reportProgress(0.3);
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('decode');
  }
  img.Image output = img.bakeOrientation(decoded);
  final int longest = output.width > output.height
      ? output.width
      : output.height;
  if (longest > longEdge) {
    final double scale = longEdge / longest;
    output = img.copyResize(
      output,
      width: (output.width * scale).round().clamp(1, output.width),
      height: (output.height * scale).round().clamp(1, output.height),
      interpolation: img.Interpolation.linear,
    );
  }
  IsolateRunner.reportProgress(0.8);
  final Uint8List encoded = Uint8List.fromList(
    img.encodeJpg(output, quality: quality),
  );
  IsolateRunner.reportProgress(1);
  return encoded;
}

const String _cache = '.cache';
const String _thumbs = 'thumbs';
