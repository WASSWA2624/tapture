import 'package:tapture/core/cloud/cloud_destination.dart';

import 'cloud_file_range_stub.dart'
    if (dart.library.io) 'cloud_file_range_io.dart'
    as range;

/// One slice of a file, read off the UI thread where the platform allows it.
Future<List<int>> readCloudFileRange(String path, int offset, int length) {
  return range.readCloudFileRange(path, offset, length);
}

/// The size of the file at [path], or null when it is not there.
Future<int?> cloudFileLength(String path) {
  return range.cloudFileLength(path);
}

/// A [CloudBytes] view of [path] that never loads the whole file.
CloudBytes cloudFile(String path, int length) {
  return (
    length: length,
    read: (int offset, int count) => readCloudFileRange(path, offset, count),
  );
}
