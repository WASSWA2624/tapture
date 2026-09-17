import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/device_profile.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/domain/setting_key.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';

final DateTime _t0 = DateTime.utc(2026, 9, 18, 8);

void main() {
  _settingsStoreSuite('the device-profile store', _openDeviceStore);
  _settingsStoreSuite('the fake', _openFakeStore);

  test(
    'a migrated device-profile map keeps operator keys and rewrites the version',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      await writeDeviceProfile(
        db,
        deviceId: 'device-a',
        operatorName: 'Ada',
        preferences: jsonEncode(<String, Object?>{
          SettingKeys.gpsEnabled.name: true,
          AppConstants.operator.initialsKey: 'AL',
        }),
        clock: FixedClock(_t0),
      );

      final SettingsStore store = await SettingsStore.open(
        db: db,
        deviceId: 'device-a',
        clock: FixedClock(_t0),
      );
      expect(store.read(SettingKeys.gpsEnabled), isTrue);
      expect(store.read(SettingKeys.autoFillDates), isTrue);

      final DeviceProfileIdentity identity = await readDeviceProfile(
        db,
        deviceId: 'device-a',
        clock: FixedClock(_t0),
      );
      final Object? decoded = jsonDecode(identity.preferences);
      expect(decoded, isA<Map<Object?, Object?>>());
      final Map<Object?, Object?> document = decoded! as Map<Object?, Object?>;
      expect(document['schemaVersion'], 1);
      expect(document[AppConstants.operator.initialsKey], 'AL');
      expect(
        (document['settings']!
            as Map<Object?, Object?>)[SettingKeys.gpsEnabled.name],
        isTrue,
      );

      _ok(await store.write(SettingKeys.grid, true));
      final DeviceProfileIdentity afterWrite = await readDeviceProfile(
        db,
        deviceId: 'device-a',
        clock: FixedClock(_t0),
      );
      final Object? rewritten = jsonDecode(afterWrite.preferences);
      expect(rewritten, isA<Map<Object?, Object?>>());
      final Map<Object?, Object?> next = rewritten! as Map<Object?, Object?>;
      expect(next[AppConstants.operator.initialsKey], 'AL');
      expect(
        (next['settings']! as Map<Object?, Object?>)[SettingKeys.grid.name],
        isTrue,
      );
    },
  );

  test('a second open reads a committed write', () async {
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final SettingsStore first = await SettingsStore.open(
      db: db,
      deviceId: 'device-a',
      clock: FixedClock(_t0),
    );
    _ok(await first.write(SettingKeys.gpsEnabled, true));

    final SettingsStore second = await SettingsStore.open(
      db: db,
      deviceId: 'device-a',
      clock: FixedClock(_t0),
    );
    expect(second.read(SettingKeys.gpsEnabled), isTrue);
  });
}

void _settingsStoreSuite(
  String name,
  Future<SettingsStore> Function({
    bool failWrites,
    Map<String, Object?>? stored,
    int? schemaVersion,
  })
  open,
) {
  group(name, () {
    test('an empty store reads every key as its default', () async {
      final SettingsStore store = await open();
      expect(store.read(SettingKeys.gpsEnabled), isFalse);
      expect(store.read(SettingKeys.autoFillDates), isTrue);
      expect(store.read(SettingKeys.photoQuality), AppConstants.images.quality);
      expect(
        store.read(SettingKeys.folderStrategy),
        AppConstants.folders.defaultStrategy,
      );
      expect(
        store.read(SettingKeys.retentionDays),
        AppConstants.retention.days,
      );
      expect(store.read(SettingKeys.openProjectId), isNull);
      expect(
        store.read(SettingKeys.confidenceHigh),
        AppConstants.confidence.high,
      );
    });

    test('a write then a read round-trips the value', () async {
      final SettingsStore store = await open();
      _ok(await store.write(SettingKeys.gpsEnabled, true));
      _ok(await store.write(SettingKeys.openProjectId, 'project-1'));
      _ok(
        await store.write(
          SettingKeys.photoQuality,
          AppConstants.images.quality,
        ),
      );

      expect(store.read(SettingKeys.gpsEnabled), isTrue);
      expect(store.read(SettingKeys.openProjectId), 'project-1');
      expect(store.read(SettingKeys.photoQuality), AppConstants.images.quality);
    });

    test('a committed write emits one change event', () async {
      final SettingsStore store = await open();
      final List<String> names = <String>[];
      final Stream<SettingKey<Object?>> stream = store.changes();
      final Future<void> first = stream.first.then((SettingKey<Object?> key) {
        names.add(key.name);
      });

      _ok(await store.write(SettingKeys.gpsEnabled, true));
      await first;

      expect(names, <String>[SettingKeys.gpsEnabled.name]);
    });

    test('a failed write emits nothing and leaves the default', () async {
      final SettingsStore store = await open(failWrites: true);
      final List<String> names = <String>[];
      final StreamSubscription<SettingKey<Object?>> subscription = store
          .changes()
          .listen((SettingKey<Object?> key) => names.add(key.name));
      addTearDown(subscription.cancel);

      final Result<void> written = await store.write(
        SettingKeys.gpsEnabled,
        true,
      );
      await pumpEventQueue();

      expect(written, isA<FailureResult<void>>());
      expect(store.read(SettingKeys.gpsEnabled), isFalse);
      expect(names, isEmpty);
    });

    test(
      'a stored map from an earlier version keeps values and defaults new keys',
      () async {
        final SettingsStore store = await open(
          stored: <String, Object?>{
            SettingKeys.gpsEnabled.name: true,
            AppConstants.operator.initialsKey: 'AL',
          },
          schemaVersion: 0,
        );

        expect(store.read(SettingKeys.gpsEnabled), isTrue);
        expect(store.read(SettingKeys.autoFillDates), isTrue);
        expect(
          store.read(SettingKeys.retentionDays),
          AppConstants.retention.days,
        );
      },
    );
  });
}

Future<SettingsStore> _openDeviceStore({
  bool failWrites = false,
  Map<String, Object?>? stored,
  int? schemaVersion,
}) async {
  final AppDatabase db = AppDatabase.memory();
  addTearDown(() async {
    try {
      await db.close();
    } on Object {
      // Already closed so the next write can fail.
    }
  });
  if (stored != null || schemaVersion != null) {
    await writeDeviceProfile(
      db,
      deviceId: 'device-a',
      operatorName: 'Ada',
      preferences: jsonEncode(<String, Object?>{
        'schemaVersion': ?schemaVersion,
        ...?stored,
      }),
      clock: FixedClock(_t0),
    );
  }
  final SettingsStore store = await SettingsStore.open(
    db: db,
    deviceId: 'device-a',
    clock: FixedClock(_t0),
  );
  if (failWrites) {
    await db.close();
  }
  return store;
}

Future<SettingsStore> _openFakeStore({
  bool failWrites = false,
  Map<String, Object?>? stored,
  int? schemaVersion,
}) async {
  return SettingsStore.fake(
    stored: stored,
    schemaVersion: schemaVersion,
    failWrites: failWrites,
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
