import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/cooperative_cancellation.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/concurrency/worker_cancellation.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Content hashing for file identity and duplicate detection.
abstract final class HashingService {
  /// SHA-256 of [file], streamed in chunks on a worker isolate.
  ///
  /// [onProgress] receives the fraction read, ending at 1.0. [cancel]
  /// completes with a `CancelledFailure` after the worker has closed the
  /// file at its next chunk, so a cancelled hash never leaves the file held
  /// open (Windows refuses to remove a file that is).
  static Future<Result<String>> sha256OfFile(
    File file, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async {
    if (cancel == null) {
      return runIsolate(_hashFileInIsolate, (
        file.path,
        null,
      ), onProgress: onProgress);
    }
    if (cancel.isCancelled) {
      return const FailureResult<String>(CancelledFailure());
    }
    final CooperativeCancellation cancellation = CooperativeCancellation(
      cancel,
    );
    try {
      return await runIsolate(_hashFileInIsolate, (
        file.path,
        cancellation.handshake,
      ), onProgress: onProgress);
    } finally {
      cancellation.close();
    }
  }

  /// Hashes a picked document without blocking the UI isolate.
  static Future<Result<String>> sha256OfBytes(Uint8List bytes) =>
      runIsolate(_hashBytesInIsolate, bytes);

  /// SHA-256 of [value]'s UTF-8 bytes.
  static String sha256OfString(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }
}

String _hashBytesInIsolate(Uint8List bytes) => sha256.convert(bytes).toString();

/// SHA-256 of [file], streamed in chunks on a worker isolate.
Future<Result<String>> sha256OfFile(
  File file, {
  CancellationToken? cancel,
  void Function(double)? onProgress,
}) {
  return HashingService.sha256OfFile(
    file,
    cancel: cancel,
    onProgress: onProgress,
  );
}

/// SHA-256 of [value]'s UTF-8 bytes.
String sha256OfString(String value) {
  return HashingService.sha256OfString(value);
}

Future<String> _hashFileInIsolate((String, SendPort?) job) async {
  final (String path, SendPort? handshake) = job;
  final WorkerCancellation? cancellation = handshake == null
      ? null
      : WorkerCancellation(handshake);
  final File file = File(path);
  final int length = file.lengthSync();
  final RandomAccessFile handle = file.openSync();
  final _DigestSink output = _DigestSink();
  final ByteConversionSink sink = sha256.startChunkedConversion(output);
  final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes);
  var read = 0;
  try {
    while (true) {
      await cancellation?.checkpoint();
      final int n = handle.readIntoSync(buffer);
      if (n == 0) {
        break;
      }
      sink.add(n == buffer.length ? buffer : buffer.sublist(0, n));
      read += n;
      if (length > 0 && read < length) {
        IsolateRunner.reportProgress(read / length);
      }
    }
    sink.close();
  } finally {
    handle.closeSync();
    cancellation?.close();
  }
  IsolateRunner.reportProgress(1);
  final Digest digest = output.digest;
  return digest.toString();
}

final class _DigestSink implements Sink<Digest> {
  late final Digest digest;

  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}
