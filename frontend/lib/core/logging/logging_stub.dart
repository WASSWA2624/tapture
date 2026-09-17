/// Web stand-in for [logging_io.dart]: no files, no yaml on disk.
String? defaultLogDirectoryPath() => null;

/// Web stand-in: the compiled-in patterns in [Logger] are used instead.
String? readSecretPatternsYaml() => null;

/// Web stand-in: the ring buffer is the only store.
void persistLogFiles({
  required String directoryPath,
  required List<String> lines,
  required int rotationCount,
  required bool rotate,
}) {
  if (directoryPath.isEmpty ||
      lines.isEmpty ||
      rotationCount < 1 ||
      rotate && !rotate) {
    return;
  }
}
