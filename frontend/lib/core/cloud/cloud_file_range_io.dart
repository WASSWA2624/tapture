import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/result.dart';

/// Reads one slice of [path] on a worker isolate.
Future<List<int>> readCloudFileRange(
  String path,
  int offset,
  int length,
) async {
  final Result<Uint8List> read = await runIsolate<List<Object>, Uint8List>(
    _readRange,
    <Object>[path, offset, length],
  );
  return read.fold((_) => const <int>[], (Uint8List bytes) => bytes);
}

/// Isolate entry. [message] is path, offset, length.
Uint8List _readRange(List<Object> message) {
  final RandomAccessFile handle = File(message[0] as String).openSync();
  try {
    handle.setPositionSync(message[1] as int);
    return handle.readSync(message[2] as int);
  } finally {
    handle.closeSync();
  }
}
