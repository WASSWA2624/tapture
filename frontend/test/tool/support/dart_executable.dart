import 'dart:io';

String dartExecutable() {
  final String suffix = Platform.isWindows ? '.exe' : '';
  final String running = Platform.resolvedExecutable;
  if (Uri.file(running).pathSegments.last == 'dart$suffix') {
    return running;
  }
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  return flutterRoot == null
      ? 'dart$suffix'
      : '$flutterRoot/bin/cache/dart-sdk/bin/dart$suffix';
}
