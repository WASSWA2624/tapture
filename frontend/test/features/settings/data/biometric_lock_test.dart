import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/settings/data/biometric_lock.dart';
import 'package:tapture/features/settings/domain/app_lock.dart';

void main() {
  test('the default factory never unlocks', () async {
    final BiometricLock lock = BiometricLock();

    expect(await lock.isAvailable(), isFalse);
    expect(await lock.unlock(), LockAttempt.unavailable);
  });

  test('the fake returns the configured attempt', () async {
    final BiometricLock lock = BiometricLock.fake(
      available: true,
      result: LockAttempt.wrong,
    );

    expect(await lock.isAvailable(), isTrue);
    expect(await lock.unlock(), LockAttempt.wrong);
  });

  test(
    'a cancelled or failed wrap returns to the PIN, never unlocked',
    () async {
      final BiometricLock cancelled = BiometricLock.wrap(
        probe: () async => true,
        authenticate: () async => false,
      );
      final BiometricLock thrown = BiometricLock.wrap(
        probe: () async => true,
        authenticate: () async => throw StateError('cancelled'),
      );

      expect(await cancelled.isAvailable(), isTrue);
      expect(await cancelled.unlock(), LockAttempt.wrong);
      expect(await thrown.unlock(), LockAttempt.unavailable);
      expect(await cancelled.unlock(), isNot(LockAttempt.unlocked));
      expect(await thrown.unlock(), isNot(LockAttempt.unlocked));
    },
  );
}
