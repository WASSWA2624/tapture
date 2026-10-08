import 'dart:io';

/// A capture store that removes a file before the purge job.
class PhotoStore {
  void forget(String path) {
    File(path).deleteSync();
  }
}
