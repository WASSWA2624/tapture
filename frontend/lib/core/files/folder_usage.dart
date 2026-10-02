import 'dart:io';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/result.dart';

/// Bytes under each of [paths], in the same order, walked on a worker
/// isolate so a large cache or project tree never stalls a frame
/// (FE-PERF-02). A folder that does not exist is null; links are not
/// followed. Screens ask this rather than walking a folder themselves
/// (FE-STR-11).
Future<Result<List<int?>>> measureFolders(List<String> paths) {
  return runIsolate(_measureAll, paths);
}

/// Isolate entry: [_bytesUnder] for every path.
List<int?> _measureAll(List<String> paths) {
  return <int?>[for (final String path in paths) _bytesUnder(path)];
}

int? _bytesUnder(String path) {
  final Directory directory = Directory(path);
  if (!directory.existsSync()) {
    return null;
  }
  var total = 0;
  for (final FileSystemEntity entity in directory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File) {
      total += entity.statSync().size;
    }
  }
  return total;
}
