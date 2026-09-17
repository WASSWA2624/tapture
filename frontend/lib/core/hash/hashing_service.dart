import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

/// Content hashing for file identity and duplicate detection.
abstract final class HashingService {
  /// SHA-256 of [file], streamed in chunks on a worker isolate.
  static Future<Result<String>> sha256OfFile(File file) {
    return runIsolate(_hashFileInIsolate, file.path);
  }

  /// SHA-256 of [value]'s UTF-8 bytes.
  static String sha256OfString(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }
}

/// SHA-256 of [file], streamed in chunks on a worker isolate.
Future<Result<String>> sha256OfFile(File file) {
  return HashingService.sha256OfFile(file);
}

/// SHA-256 of [value]'s UTF-8 bytes.
String sha256OfString(String value) {
  return HashingService.sha256OfString(value);
}

Future<String> _hashFileInIsolate(String path) async {
  final File file = File(path);
  final int length = file.lengthSync();
  final RandomAccessFile handle = file.openSync();
  final _DigestSink output = _DigestSink();
  final ByteConversionSink sink = sha256.startChunkedConversion(output);
  final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes);
  var read = 0;
  try {
    while (true) {
      final int n = handle.readIntoSync(buffer);
      if (n == 0) {
        break;
      }
      sink.add(n == buffer.length ? buffer : buffer.sublist(0, n));
      read += n;
      if (length > 0) {
        IsolateRunner.reportProgress(read / length);
      }
    }
    sink.close();
  } finally {
    handle.closeSync();
  }
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
