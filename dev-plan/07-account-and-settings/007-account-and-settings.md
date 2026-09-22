# 007 — Account and settings: local identity, the app lock and the switches later features read

**Phase** 07 · Account and settings  |  **Depends on** [001](../01-orchestration/001-project-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The whole of `features/settings/`: the local operator identity every capture is attributed to before enrolment
exists, held on the single device-profile row and shaped so signing in later adopts it rather than replacing it
(§71.2); one typed store where every app-wide preference is declared once beside its default, persisted as a
versioned JSON map on that same row and emitting a change only after the write commits, so every later phase reads a
preference through it and none by raw string key; the settings root listing the specification's eight sections, each
its own route, with the three section screens this phase owns — capture defaults, storage usage and About — so
adding a setting later is one more tile rather than a restructured screen; an optional lock on launch and resume,
where a person sets, changes or removes a PIN of which only a salted hash ever exists, in secure storage, with
biometrics offered where the device supports them and the PIN as the fallback a biometric failure always returns to;
and the one switch that stops every outbound call while capture, editing, review and export carry on untouched,
writing a single stored flag the connectivity service folds in so no feature learns about the switch itself.
Authentication belongs to the backend (§70.1) and no part of it appears here.

## Files

Operator identity:

- `frontend/lib/features/settings/domain/operator_profile.dart` (new)
- `frontend/lib/features/settings/presentation/operator_profile_screen.dart` (new)
- `frontend/lib/core/db/tables/device_profile.dart` (changed)

The preference store:

- `frontend/lib/features/settings/domain/setting_key.dart` (new)
- `frontend/lib/features/settings/domain/setting_keys.dart` (new)
- `frontend/lib/features/settings/data/settings_store.dart` (new)
- `frontend/lib/features/settings/settings.dart` (new)

The settings shell and its section screens:

- `frontend/lib/features/settings/presentation/settings_screen.dart` (new)
- `frontend/lib/features/settings/presentation/capture_settings_screen.dart` (new)
- `frontend/lib/features/settings/presentation/storage_settings_screen.dart` (new)
- `frontend/lib/features/settings/presentation/about_screen.dart` (new)
- `frontend/lib/app/router.dart` (changed)

The app lock:

- `frontend/lib/features/settings/domain/app_lock.dart` (new)
- `frontend/lib/features/settings/data/pin_lock.dart` (new)
- `frontend/lib/features/settings/data/biometric_lock.dart` (new)
- `frontend/lib/features/settings/presentation/app_lock_screen.dart` (new)
- `frontend/lib/app/route_guards.dart` (changed)
- `frontend/lib/core/lifecycle/lifecycle_observer.dart` (changed)
- `frontend/lib/core/widgets/fields/app_text_field.dart` (changed)

The offline switch:

- `frontend/lib/features/settings/presentation/offline_switch.dart` (new)
- `frontend/lib/core/network/outbound_queue.dart` (new)
- `frontend/lib/core/network/connectivity_service.dart` (changed)

Shared, carried by the work above:

- `frontend/lib/core/constants/app_constants.dart` (changed)
- `frontend/lib/core/copy/copy.dart` (changed)
- `frontend/lib/main.dart` (changed)

## Contract

```dart
final class OperatorProfile {
  const OperatorProfile({required this.name, required this.initials, this.contact, this.accountId});
  final String name;
  final String initials;
  final String? contact;
  /// Filled by enrolment; null on every pre-backend install.
  final String? accountId;
}

final class SettingKey<T> {
  const SettingKey(this.name, this.defaultValue);
  final String name;
  final T defaultValue;
}

abstract final class SettingKeys {
  static const gpsEnabled = SettingKey<bool>('capture.gps', false);
  static const offlineByChoice = SettingKey<bool>('network.offlineByChoice', false);
  // one declaration per preference, typed, with its default
}

abstract interface class SettingsStore {
  T read<T>(SettingKey<T> key);
  Future<Result<void>> write<T>(SettingKey<T> key, T value);
  Stream<SettingKey<Object?>> changes();
}

enum LockAttempt { unlocked, wrong, lockedOut, unavailable }

abstract interface class AppLock {
  bool get isEnabled;
  Future<Result<void>> setPin(String pin);
  Future<Result<void>> removePin(String currentPin);
  Future<LockAttempt> unlockWithPin(String pin);
  Future<bool> biometricsAvailable();
  Future<LockAttempt> unlockWithBiometrics();
  Future<void> hydrate();
  Duration get remainingBackoff;
}
```

## Steps

1. Land the operator profile. The screen carries name, initials and optional contact — no password, no PIN, no token
   and no credential. It is built with `AppForm`, so the unsaved-changes guard and the error summary come from the
   design system; the initials default from the name and may be overridden, the name must be non-empty and the
   initials must be one to three characters. Schema version 13 adds the nullable `accountId` column to the
   device-profile table in this migration, so enrolment fills it in later without a schema change and without
   rewriting attribution already recorded; the upgrade adds the column only where it is missing, because a fresh
   `createTable` uses the current Dart table and already has it. Presentation never sees a Drift row: the read and
   write pair hands back a primitive record and the tests inject load and save, so the screen never opens a database.
   Initials and contact get no columns of their own — step 2 keeps them as reserved top-level keys on the versioned
   preferences document. The profile row is the source of truth for the operator name, and with no first-run screen in
   the app the name is set under More → Operator.
2. Land the settings store. `SettingKeys` declares every app-wide preference once, typed, beside its default, taking
   limits and durations from `AppConstants` rather than restating them: `capture.gps` off, auto-filled dates, photo
   quality, folder strategy, naming pattern, camera default, `storage.retentionDays`, `security.appLock` and
   `network.offlineByChoice`. A key whose default comes from an `AppConstants` record getter is `static final` rather
   than `static const`, because a record getter is not const-evaluable; the default still comes from `AppConstants`.
   The declarations sit in `setting_keys.dart` beside `setting_key.dart` so one file holds one public type, while the
   interface stays in `data/settings_store.dart` as the Files list names. `SettingsStore` persists the values as a
   validated JSON map on the device-profile row with a schema version alongside; a missing or unknown key reads as its
   default, a version bump migrates the map once and rewrites it, and `changes()` emits only after the write commits,
   so a listener never observes a value that failed to persist. `SettingsStore.open` and `SettingsStore.fake` are both
   built here, so screen and controller tests never touch a database and the same suite runs against each.
3. Land the settings shell and the three section screens this phase owns. `/more` is the root: the specification's
   eight sections in order — Operator, Capture, AI, Language, Storage, Data, Security, About — grouped by
   `AppSectionHeader`, one `AppListTile` each, with every section's route declared in `router.dart`, so a section
   whose screen arrives in a later phase keeps its tile and gains a route there and the list is never restructured.
   The Data tile is labelled Files at `/more/files`, because `Copy` rejects that whole word. `settings_screen.dart`
   cannot import `router.dart` — the router imports the settings barrel — so those paths are private consts that
   must match `AppRoutes`. Capture settings carry the camera default, auto-filled dates, GPS, photo quality, folder
   strategy and naming pattern, each read and written through `settings_store.dart`, every row with a one-line
   plain-language statement of its effect and the folder-strategy row saying on screen that it applies to new files
   only. Storage settings show space used per project broken into photos, documents, audio and exports, free headroom
   from `storage_guard.dart`, a *Clear cache* that calls `cache_cleanup.dart`, and the retention-window control; the
   `dart:io` walk lives in the storage notifier rather than in `build`. About shows the application version and build
   number, licences through the platform licence page, and links to the plan and the specification: `package_info_plus`
   and `url_launcher` are not allowlisted, so About reads `deviceDescriptor` with build `1` and link opening is an
   injectable no-op until a later task approves a launcher. Capture and storage import the feature barrel for
   `SettingsStore` and are not re-exported from it, so presentation reaching the store is not a cycle. Riverpod would
   otherwise retry a failed provider for about thirty-eight seconds while holding `AsyncLoading`, so these local
   screens set `retry: (_, __) => null` and a failed read shows at once.
4. Land the app lock. A salt and a salted hash go through `secure_storage.dart` under a declared `SecretKey`; the PIN
   itself is never written, never logged and not retained after the comparison, and `AppTextField.obscureText` keeps
   it off the screen. An escalating backoff persisted alongside the hash rate-limits attempts, so a restart does not
   reset the counter: `LockAttempt.lockedOut` comes back while it runs and the screen shows the remaining time, with
   `hydrate` and `remainingBackoff` on `AppLock` giving the guard and that copy their source. PIN length, salt size
   and backoff delays come from `AppConstants.lock`. The biometric path is offered only when `biometricsAvailable()`
   is true; failure, cancellation or an unenrolled device returns to the PIN prompt and nothing falls through to an
   unlocked app. `biometric_lock.dart` wraps the platform plugin behind an interface with a hand-written fake —
   `local_auth` is not on the allowlist, so the production `BiometricLock()` reports unavailable and this step ships
   the wrap factory and the fake. Launch and resume are gated as one entry in the router's guard chain, covering every
   route including a deep link, with `AppRoutes.lock`, the `/more/security` Security tile route and a router refresh
   on the lock session; resume listens to the one `lifecycleObserverProvider`, overridden in `main.dart`. The screen
   states the recovery path in plain language — nobody can reset the PIN, the data stays on the device, and no control
   here erases anything — through `Copy` app-lock strings whose remaining-time and recovery wording never says *data*
   and never offers a wipe. The settings barrels export the new types; `app_lock_screen.dart` is not re-exported from
   `settings.dart`.
5. Land the offline switch. `offline_switch.dart` is the only writer of `SettingKeys.offlineByChoice`, through
   `settings_store.dart`; every reader asks `connectivity_service.dart` for `NetworkState`. `offlineByChoiceProvider`
   moves off the status-line stub 006 · Application shell left behind and onto this switch, re-reading the persisted
   flag rather than holding a copy, and `connectivityServiceProvider` folds it into
   `ConnectivityService.offlineOverride`, so the status line still tells offline by choice from offline by radio.
   `OutboundQueue` in `core/network/` is the send boundary the tests record against: work that would have gone online
   queues instead of failing, the queue drains when the switch is released and retries nothing while it is on, and the
   queue imports no HTTP package — the allowed egress folders pass `send` in. `SettingsScreen` composes the switch,
   which is no longer re-exported from `settings.dart` so `offline_switch.dart` can import the barrel for
   `SettingsStore`. The screen says in one line what keeps working, everything except sending, through
   `Copy.settingsOfflineTitle` and `Copy.settingsOfflineEffect`. `main.dart` opens the store for the live flag so a
   restart honours a previous choice, while widget tests keep the in-memory fake so bootstrap never opens Drift.

## Constraints

- No credential of any kind is stored or validated in this phase. A secret belongs in `secure_storage.dart` alone, and
  no secret, key, token or credential is ever a setting (FE-SEC-01, FE-SEC-02).
- The PIN never reaches the database, the preferences map, an export or a log line; only a salt and a salted hash
  exist (FE-SEC-01, FE-SEC-10).
- The device profile is one row that already exists after first launch; this phase updates it and never inserts a
  second, and nothing caches its own copy of the offline flag (FE-STATE-06).
- Presentation never sees a Drift row or a file handle; the profile screen takes a primitive record and the storage
  walk lives in its notifier (FE-STATE-05).
- The store is data-layer only and other features reach it through the settings barrel (FE-STR-04, FE-STR-08).
- Ship the hand-written fake for the store and for the biometric wrapper, so no screen and no test touches a database
  or a plugin (FE-STATE-10, FE-TEST-03, FE-STR-11).
- Rows are `AppListTile` under `AppSectionHeader`; no screen here invents a row, a switch or a section style
  (FE-CONS-06).
- GPS is off by default and the row says why it is off (FE-SEC-07).
- Clearing the cache removes derived copies only; no original file is touched (FE-SEC-08).
- A new setting has to justify why no default is right for most people (FE-SIMP-12).
- Forgetting the PIN must not offer, imply or trigger a data wipe (FE-SIMP-09).
- Offline is absolute — no feature may bypass the override, and the network boundary test from 001 · Project setup
  and guardrails must still pass (FE-SEC-03, FE-SEC-04).
- PIN length, salt size, backoff delays and every limit or duration behind a default come from `AppConstants`, not
  from a literal at the call site (FE-CODE-09).
- Every user-visible string on these screens is a `Copy` entry (FE-L10N-01).
- This phase adds no package: `local_auth`, `package_info_plus` and `url_launcher` are not on the allowlist, so the
  biometric wrapper, the build information and link opening are each an interface with an injectable default
  (FE-FLOW-06).

## Definition of done

- [x] Every record captured afterwards carries this operator name in its attribution.
- [x] The device-profile row has a nullable `accountId` from its own migration, and a database upgraded from version
      12 reads it as null.
- [x] Nothing on the operator screen authenticates anyone, and no credential is written anywhere in this phase.
- [x] The operator screen never opens a database: it loads and saves a primitive record injected into it.
- [x] Tests: `frontend/test/features/settings/domain/operator_profile_test.dart` covers the initials default and the
      name and initials validation rules.
- [x] Tests: `frontend/test/features/settings/presentation/operator_profile_screen_test.dart` covers validation, save
      and the unsaved-changes guard; `check_tests` mirrors `lib/`, so the suite sits under `presentation/`.
- [x] Tests: `frontend/test/core/db/tables/device_profile_test.dart` asserts against an in-memory database that
      `account_id` exists and reads as null, and that a version 12 profile upgraded to head gains it exactly once.
- [x] No feature reads a preference by raw string key; each key is declared once with its type and its default.
- [x] Every limit and duration behind a default comes from `AppConstants` rather than a literal at the declaration.
- [x] A stored map from an earlier schema version loads with new keys at their defaults and loses no existing value.
- [x] No change event reaches a listener until the write that caused it has committed.
- [x] Tests: `frontend/test/features/settings/domain/setting_key_test.dart` and `setting_keys_test.dart` assert the
      declared type, name and default of every key.
- [x] Tests: `frontend/test/features/settings/data/settings_store_test.dart` covers defaults, round-trip write and
      read, one change event per committed write, no event on a failed write, and the version migration.
- [x] Tests: that same suite runs unchanged against `SettingsStore.open` and `SettingsStore.fake`, and the fake passes
      every case the implementation does.
- [x] The root lists all eight specification sections in order, and a section whose screen lands later keeps its tile
      and gains a route without the list being restructured.
- [x] Adding a setting later means adding one tile, not restructuring a screen.
- [x] Changing the folder strategy affects only new files, and the screen states that.
- [x] Every capture row states its effect in one plain-language line.
- [x] A user can see space used per project, broken into photos, documents, audio and exports, and can free space
      without a file manager.
- [x] About shows a version, a build number, the platform licence page and the plan and specification links, with no
      unallowlisted package behind any of them.
- [x] Tests: widget tests for `settings_screen`, `capture_settings_screen`, `storage_settings_screen` and
      `about_screen` under `frontend/test/features/settings/presentation/` each cover loading, empty and failure
      through `AsyncValueView`.
- [x] Tests: the storage suite asserts a cache clear deletes no original file and updates the displayed totals.
- [x] With the lock on, launch and resume both prompt, and the one guard covers every route including a deep link.
- [x] Turning the lock off deletes the hash and the backoff state.
- [x] The PIN is absent from the database, the preferences map, an export and every log line, and is obscured on
      screen.
- [x] Failing or cancelling biometrics falls back to the PIN, never to no lock, and an unenrolled or unsupported
      device offers the PIN alone.
- [x] The attempt backoff survives a restart, and the screen shows the time remaining on it.
- [x] The screen explains the recovery path without offering, implying or triggering a wipe.
- [x] Tests: `frontend/test/features/settings/domain/app_lock_test.dart` and
      `frontend/test/features/settings/data/pin_lock_test.dart` cover hashing and the persisted backoff across a
      simulated restart, against a fake for `secure_storage.dart`.
- [x] Tests: `frontend/test/features/settings/data/biometric_lock_test.dart` covers the biometric-to-PIN fallback
      against the hand-written wrapper fake, and no test touches the plugin.
- [x] Tests: `frontend/test/features/settings/presentation/app_lock_screen_test.dart` covers setting, changing and
      removing the PIN.
- [x] With the switch on, no outbound call leaves the app from any feature, and capture, editing, review and export
      all still work.
- [x] Turning it off drains the queued work; turning it on retries nothing.
- [x] The status line distinguishes offline by choice from offline by radio.
- [x] The switch is the only writer of the flag, and nothing holds a second copy of it.
- [x] A restart honours the previous choice.
- [x] Tests: `frontend/test/features/settings/presentation/offline_switch_test.dart` drives a recording send boundary,
      asserting zero outbound calls with the switch on, the drain on release, and that the switch is the only writer.
- [x] Tests: `frontend/test/core/network/outbound_queue_test.dart` asserts the queue holds work while offline, drains
      on release and retries nothing while the switch is on.

## Out of scope

- Sign-in, enrolment and role grants, which 024 · The minimal backend owns; `accountId` is filled there, never here.
- The AI, Language and Files section screens; their tiles route to nothing until those phases land.
- Project-scoped switches, which 008 · Projects owns.
