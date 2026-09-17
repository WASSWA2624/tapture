import 'dart:io';

/// The only place a file may be removed, after the retention window.
class PurgeJob {
  void run(String path) {
    File(path).deleteSync();
  }
}
