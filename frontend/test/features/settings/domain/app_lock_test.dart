import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/settings/domain/app_lock.dart';

void main() {
  test('a PIN is four to eight digits and nothing else', () {
    expect(isAppLockPin('1234'), isTrue);
    expect(isAppLockPin('12345678'), isTrue);
    expect(isAppLockPin('123'), isFalse);
    expect(isAppLockPin('123456789'), isFalse);
    expect(isAppLockPin('12a4'), isFalse);
    expect(isAppLockPin(''), isFalse);
  });

  test('every lock attempt is named', () {
    expect(LockAttempt.values, <LockAttempt>[
      LockAttempt.unlocked,
      LockAttempt.wrong,
      LockAttempt.lockedOut,
      LockAttempt.unavailable,
    ]);
  });
}
