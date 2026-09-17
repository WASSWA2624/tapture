/// Web stand-in: no durable file.
String defaultDeviceIdPath() => '';

/// Web stand-in: nothing on disk.
String? readDeviceIdFile(String path) {
  if (path.isEmpty) {
    return null;
  }
  return null;
}

/// Web stand-in: the in-process cache is the only store.
void writeDeviceIdFile(String path, String id, DateTime at) {
  if (path.isEmpty || id.isEmpty) {
    return;
  }
  at.toIso8601String();
}

/// Web stand-in for model and OS version.
({String model, String osVersion}) platformIdentity() {
  return (model: 'web', osVersion: 'web');
}
