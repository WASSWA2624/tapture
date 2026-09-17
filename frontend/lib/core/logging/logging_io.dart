import 'dart:io';

/// A writable folder for rotating logs until the files service exists.
String? defaultLogDirectoryPath() {
  return '${Directory.systemTemp.path}/tapture-logs';
}

/// The contents of `tool/secret_patterns.yaml`, or null when it is not on disk.
String? readSecretPatternsYaml() {
  for (final String path in <String>[
    'tool/secret_patterns.yaml',
    '../tool/secret_patterns.yaml',
  ]) {
    final File file = File(path);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  return null;
}

/// Writes [lines] to `tapture.log` and, on rotate, copies into numbered slots.
///
/// Slots are overwritten rather than removed so this never calls `File.delete`
/// (FE-SEC-08).
void persistLogFiles({
  required String directoryPath,
  required List<String> lines,
  required int rotationCount,
  required bool rotate,
}) {
  final Directory directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  final File current = File('$directoryPath/tapture.log');
  if (rotate && current.existsSync()) {
    for (int index = rotationCount; index >= 1; index--) {
      final File source = index == 1
          ? current
          : File('$directoryPath/tapture.log.${index - 1}');
      if (!source.existsSync()) {
        continue;
      }
      File(
        '$directoryPath/tapture.log.$index',
      ).writeAsStringSync(source.readAsStringSync());
    }
  }
  current.writeAsStringSync(lines.join('\n'));
}
