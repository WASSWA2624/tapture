import 'dart:async';
import 'dart:convert';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/device_profile.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/setting_key.dart';

/// Typed, versioned preferences persisted on the single device-profile row.
///
/// Other features reach this through the settings barrel. Secrets never
/// pass through here (FE-SEC-01).
abstract interface class SettingsStore {
  /// The value stored for [key], or [SettingKey.defaultValue] when missing.
  T read<T>(SettingKey<T> key);

  /// Persists [value] for [key] and, after the write commits, emits [key].
  Future<Result<void>> write<T>(SettingKey<T> key, T value);

  /// One event per committed write. A failed write emits nothing.
  Stream<SettingKey<Object?>> changes();

  /// Opens against [db], migrating a stored map from an earlier version once.
  static Future<SettingsStore> open({
    required AppDatabase db,
    required String deviceId,
    Clock clock = const SystemClock(),
  }) {
    return _DeviceSettingsStore.open(db: db, deviceId: deviceId, clock: clock);
  }

  /// In-memory stand-in so screen tests never open a database (FE-TEST-03).
  factory SettingsStore.fake({
    Map<String, Object?>? stored,
    int? schemaVersion,
    bool failWrites = false,
  }) {
    return _FakeSettingsStore(
      stored: stored,
      schemaVersion: schemaVersion,
      failWrites: failWrites,
    );
  }
}

const int _schemaVersion = 1;
const String _schemaVersionKey = 'schemaVersion';
const String _settingsKey = 'settings';

final Set<String> _reservedKeys = <String>{
  _schemaVersionKey,
  _settingsKey,
  AppConstants.operator.initialsKey,
  AppConstants.operator.contactKey,
};

T _readValue<T>(Map<String, Object?> values, SettingKey<T> key) {
  final Object? raw = values[key.name];
  if (raw is T) {
    return raw;
  }
  if (raw == null && null is T) {
    return raw as T;
  }
  if (key.defaultValue is double && raw is num) {
    return raw.toDouble() as T;
  }
  return key.defaultValue;
}

bool _isEncodable(Object? value) {
  return value == null || value is bool || value is num || value is String;
}

Map<String, Object?> _decodeDocument(String raw) {
  if (raw.isEmpty) {
    return <String, Object?>{};
  }
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is Map<String, Object?>) {
      return Map<String, Object?>.from(decoded);
    }
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
  } on FormatException {
    // A broken map is treated as empty so a save can rewrite it.
  }
  return <String, Object?>{};
}

({int version, Map<String, Object?> settings, Map<String, Object?> reserved})
_splitDocument(Map<String, Object?> document) {
  final Object? versionRaw = document[_schemaVersionKey];
  final int version = versionRaw is int ? versionRaw : 0;
  final Map<String, Object?> settings = <String, Object?>{};
  final Map<String, Object?> reserved = <String, Object?>{};
  final Object? nested = document[_settingsKey];
  if (nested is Map) {
    settings.addAll(Map<String, Object?>.from(nested));
  }
  for (final MapEntry<String, Object?> entry in document.entries) {
    if (entry.key == _schemaVersionKey || entry.key == _settingsKey) {
      continue;
    }
    if (_reservedKeys.contains(entry.key)) {
      reserved[entry.key] = entry.value;
      continue;
    }
    settings.putIfAbsent(entry.key, () => entry.value);
  }
  return (version: version, settings: settings, reserved: reserved);
}

String _encodeDocument({
  required Map<String, Object?> settings,
  required Map<String, Object?> reserved,
}) {
  return jsonEncode(<String, Object?>{
    _schemaVersionKey: _schemaVersion,
    _settingsKey: settings,
    ...reserved,
  });
}

final class _DeviceSettingsStore implements SettingsStore {
  _DeviceSettingsStore._({
    required this._db,
    required this._deviceId,
    required this._clock,
    required this._values,
    required this._reserved,
  });

  static Future<_DeviceSettingsStore> open({
    required AppDatabase db,
    required String deviceId,
    required Clock clock,
  }) async {
    final DeviceProfileIdentity identity = await readDeviceProfile(
      db,
      deviceId: deviceId,
      clock: clock,
    );
    final ({
      int version,
      Map<String, Object?> settings,
      Map<String, Object?> reserved,
    })
    split = _splitDocument(_decodeDocument(identity.preferences));
    final _DeviceSettingsStore store = _DeviceSettingsStore._(
      db: db,
      deviceId: deviceId,
      clock: clock,
      values: split.settings,
      reserved: split.reserved,
    );
    if (split.version < _schemaVersion) {
      final Result<void> rewritten = await store._persist();
      if (rewritten is FailureResult<void>) {
        return store;
      }
    }
    return store;
  }

  final AppDatabase _db;
  final String _deviceId;
  final Clock _clock;
  final Map<String, Object?> _values;
  final Map<String, Object?> _reserved;
  final StreamController<SettingKey<Object?>> _changes =
      StreamController<SettingKey<Object?>>.broadcast();

  @override
  T read<T>(SettingKey<T> key) => _readValue(_values, key);

  @override
  Future<Result<void>> write<T>(SettingKey<T> key, T value) async {
    if (!_isEncodable(value)) {
      return const FailureResult<void>(
        ValidationFailure(
          message: 'That preference cannot be stored.',
          recoveryAction: 'Choose a supported value and save again.',
        ),
      );
    }
    final Map<String, Object?> next = <String, Object?>{
      ..._values,
      key.name: value,
    };
    final Result<void> persisted = await _persist(next);
    if (persisted is FailureResult<void>) {
      return persisted;
    }
    _values[key.name] = value;
    _changes.add(SettingKey<Object?>(key.name, key.defaultValue));
    return persisted;
  }

  @override
  Stream<SettingKey<Object?>> changes() => _changes.stream;

  Future<Result<void>> _persist([Map<String, Object?>? values]) {
    return Result.captureAsync(() async {
      final DeviceProfileIdentity current = await readDeviceProfile(
        _db,
        deviceId: _deviceId,
        clock: _clock,
      );
      final ({
        int version,
        Map<String, Object?> settings,
        Map<String, Object?> reserved,
      })
      split = _splitDocument(_decodeDocument(current.preferences));
      _reserved
        ..clear()
        ..addAll(split.reserved);
      await writeDeviceProfile(
        _db,
        deviceId: _deviceId,
        operatorName: current.operatorName,
        preferences: _encodeDocument(
          settings: values ?? _values,
          reserved: split.reserved,
        ),
        clock: _clock,
      );
    });
  }
}

final class _FakeSettingsStore implements SettingsStore {
  _FakeSettingsStore({
    Map<String, Object?>? stored,
    int? schemaVersion,
    required this.failWrites,
  }) {
    final Map<String, Object?> document = <String, Object?>{
      ...?stored,
      _schemaVersionKey: ?schemaVersion,
    };
    final ({
      int version,
      Map<String, Object?> settings,
      Map<String, Object?> reserved,
    })
    split = _splitDocument(document);
    _values.addAll(split.settings);
    _reserved.addAll(split.reserved);
  }

  final bool failWrites;
  final Map<String, Object?> _values = <String, Object?>{};
  final Map<String, Object?> _reserved = <String, Object?>{};
  final StreamController<SettingKey<Object?>> _changes =
      StreamController<SettingKey<Object?>>.broadcast();

  @override
  T read<T>(SettingKey<T> key) => _readValue(_values, key);

  @override
  Future<Result<void>> write<T>(SettingKey<T> key, T value) async {
    if (!_isEncodable(value)) {
      return const FailureResult<void>(
        ValidationFailure(
          message: 'That preference cannot be stored.',
          recoveryAction: 'Choose a supported value and save again.',
        ),
      );
    }
    if (failWrites) {
      return const FailureResult<void>(
        StorageFailure(
          message: 'The preference could not be saved on this device.',
          recoveryAction: 'Try again. Your last change was not stored.',
        ),
      );
    }
    _values[key.name] = value;
    _changes.add(SettingKey<Object?>(key.name, key.defaultValue));
    return const Success<void>(null);
  }

  @override
  Stream<SettingKey<Object?>> changes() => _changes.stream;
}
