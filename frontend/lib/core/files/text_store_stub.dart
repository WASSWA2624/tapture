/// Web stand-in: no durable file.
String defaultPreferencesPath() => '';

/// Web stand-in: no durable file.
String preferencePath(String key) => '';

/// Web stand-in: nothing on disk.
String? readTextFile(String path) {
  if (path.isEmpty) {
    return null;
  }
  return null;
}

/// Web stand-in: the in-process fake is the only store.
void writeTextFile(String path, String contents) {
  if (path.isEmpty || contents.isEmpty) {
    return;
  }
}
