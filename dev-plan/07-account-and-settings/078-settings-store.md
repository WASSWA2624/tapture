# 078 — Settings store

**Phase** 07 · Account and settings  |  **Depends on** [020](../02-foundation/020-app-constants.md), [051](../04-data-layer/051-tombstones-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One typed store for every app-wide preference, with each key declared once beside its default, persisted in the device
profile row, versioned, and emitting a change so screens react without a refresh call. Later phases read preferences
only through this.

## Files

- `frontend/lib/features/settings/domain/setting_key.dart` (new)
- `frontend/lib/features/settings/data/settings_store.dart` (new)
- `frontend/lib/features/settings/settings.dart` (new)

## Contract

```dart
final class SettingKey<T> {
  const SettingKey(this.name, this.defaultValue);
  final String name;
  final T defaultValue;
}

abstract final class SettingKeys {
  static const gpsEnabled = SettingKey<bool>('capture.gps', false);
  // one declaration per preference, typed, with its default
}

abstract interface class SettingsStore {
  T read<T>(SettingKey<T> key);
  Future<Result<void>> write<T>(SettingKey<T> key, T value);
  Stream<SettingKey<Object?>> changes();
}
```

## Steps

1. Declare every key in `SettingKeys`, taking limits and durations from `AppConstants` rather than restating them.
2. Persist the values as a validated JSON map on the device profile row, with a schema version alongside.
3. On read, treat a missing or unknown key as its default; on version bump, migrate the map once and rewrite it.
4. Emit on `changes()` only after the write commits, so a listener never observes a value that failed to persist.

## Constraints

- No secret, key, token or credential is ever a setting; those live in `secure_storage.dart` alone (FE-SEC-01).
- The store is data-layer only and is reached by other features through the settings barrel (FE-STR-04, FE-STR-08).
- Ship the hand-written fake so screen and controller tests never touch a database (FE-STATE-10, FE-TEST-03).

## Definition of done

- [ ] No feature reads a preference by raw string key; each key is declared once with its type and default.
- [ ] A stored map from an earlier version loads with new keys at their defaults and loses no existing value.
- [ ] Tests: unit tests of defaults, round-trip write and read, one change event per committed write, no event on a
  failed write, and the version migration; the fake passes the same suite as the implementation.
