import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import 'app_version.dart';
import 'device_stub.dart' if (dart.library.io) 'device_io.dart' as io;

/// The type this file is named for (FE-STR-06). The contract name is
/// [DeviceDescriptor].
typedef DeviceIdentity = DeviceDescriptor;

/// Model, OS version and application version for audit rows.
///
/// No advertising identifier, IMEI or hardware serial (FE-SEC-07, FE-SEC-10).
final class DeviceDescriptor {
  /// Creates a descriptor.
  const DeviceDescriptor({
    required this.model,
    required this.osVersion,
    required this.appVersion,
  });

  /// A hand-written stand-in so tests never touch the platform (FE-TEST-03).
  const DeviceDescriptor.fake({
    this.model = 'test-model',
    this.osVersion = 'test-os',
    this.appVersion = '1.0.0',
  });

  /// The device model where the platform reports one. `dart:io` reports
  /// none, and no plugin reads it (no hardware identifier, FE-SEC-07), so on
  /// a device this is the operating system name: `android`, `ios`,
  /// `windows`, `macos`, `linux`, or `web` in a browser.
  final String model;

  /// The operating system version the platform reports.
  final String osVersion;

  /// The application version this binary was built as.
  final String appVersion;
}

/// In-process cache used when no file path exists (web).
String? _processId;

/// The device identifier, minted once and then read back.
///
/// [clock] and [ids] are required so this function never reads the system
/// clock or generates an id inline (FE-STR-11). [memory] is the in-memory
/// fake; [filePath] is the durable store a restart and an update both read.
Future<String> deviceId({
  required Clock clock,
  required IdService ids,
  Map<String, String>? memory,
  String? filePath,
  Future<String?> Function()? readStored,
  Future<void> Function(String id)? writeStored,
}) async {
  final String? stored = await readStored?.call();
  if (stored != null && stored.isNotEmpty) {
    return stored;
  }
  if (memory != null) {
    final String? existing = memory['id'];
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final String id = ids.newId();
    memory['id'] = id;
    memory['mintedAt'] = clock.nowUtc().toIso8601String();
    return id;
  }
  final String path = filePath ?? io.defaultDeviceIdPath();
  if (path.isNotEmpty) {
    final String? existing = io.readDeviceIdFile(path);
    if (existing != null) {
      await writeStored?.call(existing);
      return existing;
    }
    final String id = ids.newId();
    io.writeDeviceIdFile(path, id, clock.nowUtc());
    await writeStored?.call(id);
    return id;
  }
  if (_processId != null) {
    return _processId!;
  }
  clock.nowUtc();
  return _processId = ids.newId();
}

/// The descriptor this device and this binary report.
///
/// Pass [fake] so tests never read the platform (FE-TEST-03).
Future<DeviceDescriptor> deviceDescriptor({DeviceDescriptor? fake}) async {
  if (fake != null) {
    return fake;
  }
  final ({String model, String osVersion}) platform = io.platformIdentity();
  return DeviceDescriptor(
    model: platform.model,
    osVersion: platform.osVersion,
    appVersion: appVersionName,
  );
}

/// The id a build before task 078 kept in the OS temp folder, or null when
/// there is none (and always on web). Read once, to carry that id into the
/// device profile; nothing writes the file any more. [filePath] overrides
/// the temp location for tests.
String? legacyDeviceId({String? filePath}) {
  try {
    return io.readDeviceIdFile(filePath ?? io.defaultDeviceIdPath());
  } on Object {
    return null;
  }
}
