import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/image_resize.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/hash/hashing_service.dart';

/// Reduced copies for upload, written atomically under `.cache/upload/`.
abstract interface class CompressedCopy {
  /// Writes under [storageRoot] through [FileWriter]. Tests pass
  /// [StorageRoot.fake] and [decode] so a suite never needs dart:ui.
  factory CompressedCopy({
    required StorageRoot storageRoot,
    FileReader? files,
    FileWriter? writer,
    Future<List<int>> Function(
      String sourcePath, {
      required int longEdge,
      required int quality,
    })?
    decode,
  }) {
    return _CompressedCopy(
      storageRoot: storageRoot,
      decode: decode,
      files: files,
      writer: writer,
    );
  }

  /// A long-edge-capped copy of [sourcePath]. [longEdge] and [quality]
  /// default to [AppConstants.images].
  Future<Result<WrittenFile>> reduce(
    String sourcePath, {
    int? longEdge,
    int? quality,
  });

  /// Reduces a photo read through the platform store, preserving native cache keys.
  Future<Result<WrittenFile>> reduceStored(
    String storagePath, {
    CancellationToken? cancel,
  });
}

final class _CompressedCopy implements CompressedCopy {
  _CompressedCopy({
    required StorageRoot storageRoot,
    required this._decode,
    FileReader? files,
    FileWriter? writer,
  }) : _storageRoot = storageRoot,
       _writer = writer ?? FileWriter(storageRoot: storageRoot),
       _files = files ?? FileReader(storageRoot: storageRoot);

  final StorageRoot _storageRoot;
  final FileWriter _writer;
  final FileReader _files;
  final Future<List<int>> Function(
    String sourcePath, {
    required int longEdge,
    required int quality,
  })?
  _decode;

  @override
  Future<Result<WrittenFile>> reduceStored(
    String storagePath, {
    CancellationToken? cancel,
  }) async {
    final Result<Uint8List> read = await _files.read(storagePath);
    if (read case FailureResult<Uint8List>(:final failure)) {
      return FailureResult<WrittenFile>(failure);
    }
    final Uint8List original = (read as Success<Uint8List>).value;
    final Result<String> hash = await runIsolate(
      _hashBytes,
      original,
      cancel: cancel,
    );
    if (hash case FailureResult<String>(:final failure)) {
      return FailureResult<WrittenFile>(failure);
    }
    final String relative =
        '$_cache/$_upload/${(hash as Success<String>).value}_${AppConstants.images.longEdge}';
    final Result<Uint8List> cached = await _files.read(relative);
    if (cached case Success<Uint8List>(:final value)) {
      final Result<String> digest = await runIsolate(
        _hashBytes,
        value,
        cancel: cancel,
      );
      return digest.map(
        (String hash) => WrittenFile(
          relativePath: relative,
          sha256: hash,
          byteLength: value.length,
        ),
      );
    }
    final Result<Uint8List> resized = await ImageResize.fit(
      original,
      longEdge: AppConstants.images.longEdge,
      quality: AppConstants.images.quality,
      cancel: cancel,
    );
    return switch (resized) {
      FailureResult<Uint8List>(:final failure) => FailureResult<WrittenFile>(
        failure,
      ),
      Success<Uint8List>(:final value) => _writer.write(
        Stream<List<int>>.value(value),
        relative,
      ),
    };
  }

  @override
  Future<Result<WrittenFile>> reduce(
    String sourcePath, {
    int? longEdge,
    int? quality,
  }) async {
    try {
      final int edge = longEdge ?? AppConstants.images.longEdge;
      final int jpegQuality = quality ?? AppConstants.images.quality;
      if (edge <= 0 || jpegQuality < 1) {
        return const FailureResult<WrittenFile>(
          ValidationFailure(
            message: 'That image size is not valid.',
            recoveryAction: 'Use the app upload size and try again.',
          ),
        );
      }
      final File source = File(sourcePath);
      if (!source.existsSync()) {
        return FailureResult<WrittenFile>(_missing(sourcePath));
      }
      final Result<String> hashed = await sha256OfFile(source);
      switch (hashed) {
        case FailureResult<String>(:final failure):
          return FailureResult<WrittenFile>(failure);
        case Success<String>(:final value):
          final Result<Directory> root = await _storageRoot.resolve();
          switch (root) {
            case FailureResult<Directory>(:final failure):
              return FailureResult<WrittenFile>(failure);
            case Success<Directory>(value: final Directory rootDir):
              final String relative = '$_cache/$_upload/${value}_$edge';
              final File dest = File('${rootDir.path}/$relative');
              if (dest.existsSync()) {
                return _fromCached(dest, relative);
              }
              final List<int> bytes = await _resized(
                sourcePath,
                longEdge: edge,
                quality: jpegQuality,
              );
              if (bytes.isEmpty) {
                return const FailureResult<WrittenFile>(
                  StorageFailure(
                    message: 'That photo could not be read as an image.',
                    recoveryAction: 'Capture the photo again, then try again.',
                  ),
                );
              }
              return _writer.write(
                Stream<List<int>>.fromIterable(<List<int>>[bytes]),
                relative,
              );
          }
      }
    } on Failure catch (failure) {
      return FailureResult<WrittenFile>(failure);
    } on Object {
      return const FailureResult<WrittenFile>(
        StorageFailure(
          message: 'The reduced copy could not be created on this device.',
          recoveryAction: 'Free space or allow storage access, then try again.',
        ),
      );
    }
  }

  Future<Result<WrittenFile>> _fromCached(File dest, String relative) async {
    final Result<String> hashed = await sha256OfFile(dest);
    switch (hashed) {
      case FailureResult<String>(:final failure):
        return FailureResult<WrittenFile>(failure);
      case Success<String>(:final value):
        return Success<WrittenFile>(
          WrittenFile(
            relativePath: relative,
            sha256: value,
            byteLength: dest.lengthSync(),
          ),
        );
    }
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

StorageFailure _missing(String path) {
  return StorageFailure(
    message: 'Tapture could not find $path.',
    recoveryAction: 'Capture the photo again, then try again.',
  );
}

String _hashBytes(Uint8List bytes) => sha256.convert(bytes).toString();

const String _cache = '.cache';
const String _upload = 'upload';
