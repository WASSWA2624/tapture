import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/hash/hashing_service.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/settings/data/biometric_lock.dart';
import 'package:tapture/features/settings/data/pin_lock.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/domain/app_lock.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';

void main() {
  test('setPin stores a salted hash and never the PIN itself', () async {
    const String pin = '2468';
    final Map<SecretKey, String> backing = <SecretKey, String>{};
    final Map<String, String> preferences = <String, String>{};
    final Map<String, String> database = <String, String>{};
    final SettingsStore settings = SettingsStore.fake();
    final PinLock lock = PinLock.fake(
      backing: backing,
      preferences: preferences,
      database: database,
      settings: settings,
    );

    final Result<void> written = await lock.setPin(pin);

    expect(written, isA<Success<void>>());
    expect(lock.isEnabled, isTrue);
    expect(settings.read(SettingKeys.appLockEnabled), isTrue);
    expect(backing.containsKey(SecretKey.pinSalt), isTrue);
    expect(backing.containsKey(SecretKey.pinHash), isTrue);
    expect(backing.values, isNot(contains(pin)));
    expect(preferences.values, isNot(contains(pin)));
    expect(database.values, isNot(contains(pin)));
    expect(
      backing[SecretKey.pinHash],
      HashingService.sha256OfString('${backing[SecretKey.pinSalt]}$pin'),
    );
  });

  test('the attempt backoff survives a simulated restart', () async {
    final DateTime now = DateTime.utc(2026, 9, 18, 1);
    final Map<SecretKey, String> backing = <SecretKey, String>{};
    final PinLock first = PinLock.fake(
      backing: backing,
      clock: FixedClock(now),
    );
    await first.setPin('1357');
    expect(await first.unlockWithPin('0000'), LockAttempt.wrong);

    final PinLock restarted = PinLock.fake(
      backing: backing,
      clock: FixedClock(now),
    );
    expect(restarted.isEnabled, isTrue);
    expect(await restarted.unlockWithPin('1357'), LockAttempt.lockedOut);
    expect(restarted.remainingBackoff, greaterThan(Duration.zero));

    final PinLock later = PinLock.fake(
      backing: backing,
      clock: FixedClock(now.add(const Duration(seconds: 2))),
    );
    expect(await later.unlockWithPin('1357'), LockAttempt.unlocked);
  });

  test('failing biometrics falls back to the PIN, never to no lock', () async {
    final Map<SecretKey, String> backing = <SecretKey, String>{};
    final PinLock lock = PinLock.fake(
      backing: backing,
      biometrics: BiometricLock.fake(
        available: true,
        result: LockAttempt.wrong,
      ),
    );
    await lock.setPin('8642');

    expect(await lock.biometricsAvailable(), isTrue);
    expect(await lock.unlockWithBiometrics(), LockAttempt.wrong);
    expect(lock.isEnabled, isTrue);
    expect(backing.containsKey(SecretKey.pinHash), isTrue);
    expect(await lock.unlockWithPin('8642'), LockAttempt.unlocked);
  });

  test('an unenrolled biometric path stays on the PIN', () async {
    final Map<SecretKey, String> backing = <SecretKey, String>{};
    final PinLock lock = PinLock.fake(
      backing: backing,
      biometrics: BiometricLock.fake(),
    );
    await lock.setPin('8642');

    expect(await lock.biometricsAvailable(), isFalse);
    expect(await lock.unlockWithBiometrics(), LockAttempt.unavailable);
    expect(lock.isEnabled, isTrue);
    expect(await lock.unlockWithPin('8642'), LockAttempt.unlocked);
  });

  test('turning the lock off deletes the hash and the backoff', () async {
    final Map<SecretKey, String> backing = <SecretKey, String>{};
    final SettingsStore settings = SettingsStore.fake();
    final PinLock lock = PinLock.fake(backing: backing, settings: settings);
    await lock.setPin('1111');
    await lock.unlockWithPin('0000');
    expect(backing.containsKey(SecretKey.pinBackoff), isTrue);

    final PinLock afterWait = PinLock.fake(
      backing: backing,
      settings: settings,
      clock: FixedClock(DateTime.utc(2030)),
    );
    final Result<void> removed = await afterWait.removePin('1111');

    expect(removed, isA<Success<void>>());
    expect(afterWait.isEnabled, isFalse);
    expect(settings.read(SettingKeys.appLockEnabled), isFalse);
    expect(backing.containsKey(SecretKey.pinHash), isFalse);
    expect(backing.containsKey(SecretKey.pinSalt), isFalse);
    expect(backing.containsKey(SecretKey.pinBackoff), isFalse);
  });

  test('a short PIN is rejected and writes nothing', () async {
    final Map<SecretKey, String> backing = <SecretKey, String>{};
    final PinLock lock = PinLock.fake(backing: backing);

    final Result<void> written = await lock.setPin('12');

    expect(written, isA<FailureResult<void>>());
    expect(lock.isEnabled, isFalse);
    expect(backing, isEmpty);
  });
}
