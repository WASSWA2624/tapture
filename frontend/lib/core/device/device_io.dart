import 'dart:io';

/// A writable path for the device id until the files service exists.
String defaultDeviceIdPath() {
  return '${Directory.systemTemp.path}/tapture-device/device.id';
}

/// The first token of the persisted file, or null when it is missing.
String? readDeviceIdFile(String path) {
  if (path.isEmpty) {
    return null;
  }
  final File file = File(path);
  if (!file.existsSync()) {
    return null;
  }
  final String text = file.readAsStringSync().trim();
  if (text.isEmpty) {
    return null;
  }
  return text.split(RegExp(r'\s+')).first;
}

/// Writes [id] and the mint time. Overwrites; never deletes (FE-SEC-08).
void writeDeviceIdFile(String path, String id, DateTime at) {
  final File file = File(path);
  if (!file.parent.existsSync()) {
    file.parent.createSync(recursive: true);
  }
  file.writeAsStringSync('$id ${at.toUtc().toIso8601String()}');
}

/// Model and OS version from dart:io, with no hardware serial (FE-SEC-07).
({String model, String osVersion}) platformIdentity() {
  return (
    model: Platform.operatingSystem,
    osVersion: Platform.operatingSystemVersion,
  );
}
