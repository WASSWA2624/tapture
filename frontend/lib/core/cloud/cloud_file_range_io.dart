import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_upload_context.dart';

final Map<String, RandomAccessFile> _workerFiles = {};

/// Reads one slice of [path] on a worker isolate.
Future<List<int>> readCloudFileRange(
  String path,
  int offset,
  int length,
) async {
  if (CloudUploadContext.isWorker) {
    // The transfer itself already runs on a worker. Avoid spawning another
    // isolate for every bounded hashing or streaming slice.
    final RandomAccessFile handle = _workerFiles.putIfAbsent(
      path,
      () => File(path).openSync(),
    );
    handle.setPositionSync(offset);
    return handle.readSync(length);
  }
  final Result<Uint8List> read = await runIsolate<List<Object>, Uint8List>(
    _readRange,
    <Object>[path, offset, length],
  );
  return read.fold((_) => const <int>[], (Uint8List bytes) => bytes);
}

/// Releases held source handles when the transfer ends. Hashing and uploading
/// use the same open file, so atomic replacement cannot mix source versions.
void closeCloudFileRanges() {
  for (final RandomAccessFile handle in _workerFiles.values) {
    handle.closeSync();
  }
  _workerFiles.clear();
}

/// The size of [path], or null when it cannot be read.
Future<int?> cloudFileLength(String path) async {
  try {
    return await File(path).length();
  } on FileSystemException {
    return null;
  }
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
