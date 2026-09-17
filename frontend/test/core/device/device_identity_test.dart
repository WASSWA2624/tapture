import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  final Clock clock = FixedClock(DateTime.utc(2026, 9, 17, 8));

  test('the in-memory fake returns the same id across two reads', () async {
    final IdService ids = UuidV7Service.sequence(clock);
    final Map<String, String> memory = <String, String>{};

    final String first = await deviceId(clock: clock, ids: ids, memory: memory);
    final String second = await deviceId(
      clock: clock,
      ids: ids,
      memory: memory,
    );

    expect(first, isNotEmpty);
    expect(second, first);
    expect(memory['id'], first);
  });

  test('a persisted id survives a restart and an app update', () async {
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture-device-',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final String path = '${directory.path}/device.id';
    final IdService firstIds = UuidV7Service.sequence(clock);
    final String minted = await deviceId(
      clock: clock,
      ids: firstIds,
      filePath: path,
    );

    final IdService restarted = UuidV7Service.sequence(clock);
    final String afterRestart = await deviceId(
      clock: clock,
      ids: restarted,
      filePath: path,
    );
    final IdService afterUpdate = UuidV7Service.sequence(clock);
    final String afterAppUpdate = await deviceId(
      clock: clock,
      ids: afterUpdate,
      filePath: path,
    );
    final DeviceDescriptor before = await deviceDescriptor(
      fake: const DeviceDescriptor.fake(appVersion: '1.0.0'),
    );
    final DeviceDescriptor after = await deviceDescriptor(
      fake: const DeviceDescriptor.fake(appVersion: '1.1.0'),
    );

    expect(afterRestart, minted);
    expect(afterAppUpdate, minted);
    expect(before.appVersion, '1.0.0');
    expect(after.appVersion, '1.1.0');
    expect(File(path).readAsStringSync(), contains(minted));
  });

  test(
    'the descriptor exposes model, OS version and app version only',
    () async {
      const DeviceDescriptor fake = DeviceDescriptor.fake(
        model: 'Pixel',
        osVersion: '16',
        appVersion: '1.0.0',
      );
      final DeviceDescriptor descriptor = await deviceDescriptor(fake: fake);

      expect(descriptor.model, 'Pixel');
      expect(descriptor.osVersion, '16');
      expect(descriptor.appVersion, '1.0.0');
      expect(descriptor, isNot(isA<Map<String, Object?>>()));
    },
  );

  test('the platform descriptor fills the three audit fields', () async {
    final DeviceDescriptor descriptor = await deviceDescriptor();

    expect(descriptor.model, isNotEmpty);
    expect(descriptor.osVersion, isNotEmpty);
    expect(descriptor.appVersion, isNotEmpty);
  });
}
