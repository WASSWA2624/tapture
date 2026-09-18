import '../domain/app_lock.dart';

/// Platform biometric unlock, behind an interface so screens and tests
/// never touch the plugin (FE-STR-11, FE-TEST-03).
///
/// The default factory is unavailable: `local_auth` is not on the
/// allowlist, and adding it is its own task (FE-FLOW-06). [wrap] is the
/// hook a later task passes the plugin through.
abstract interface class BiometricLock {
  /// Whether the device has an enrolled biometric.
  Future<bool> isAvailable();

  /// One biometric try. Cancel, failure and an unenrolled device never
  /// report [LockAttempt.unlocked].
  Future<LockAttempt> unlock();

  /// Production stand-in until a later task adds the platform plugin.
  factory BiometricLock() = _UnavailableBiometricLock;

  /// Hand-written stand-in driven by [available] and [result].
  factory BiometricLock.fake({
    bool available = false,
    LockAttempt result = LockAttempt.unavailable,
  }) {
    return _FakeBiometricLock(available: available, result: result);
  }

  /// Wraps [probe] and [authenticate] from the platform plugin.
  factory BiometricLock.wrap({
    required Future<bool> Function() probe,
    required Future<bool> Function() authenticate,
  }) {
    return _WrappedBiometricLock(probe, authenticate);
  }
}

final class _UnavailableBiometricLock implements BiometricLock {
  const _UnavailableBiometricLock();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<LockAttempt> unlock() async => LockAttempt.unavailable;
}

final class _FakeBiometricLock implements BiometricLock {
  _FakeBiometricLock({
    this.available = false,
    this.result = LockAttempt.unavailable,
  });

  final bool available;
  final LockAttempt result;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<LockAttempt> unlock() async => result;
}

final class _WrappedBiometricLock implements BiometricLock {
  _WrappedBiometricLock(this._probe, this._authenticate);

  final Future<bool> Function() _probe;
  final Future<bool> Function() _authenticate;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _probe();
    } on Object {
      return false;
    }
  }

  @override
  Future<LockAttempt> unlock() async {
    try {
      if (!await _authenticate()) {
        return LockAttempt.wrong;
      }
      return LockAttempt.unlocked;
    } on Object {
      return LockAttempt.unavailable;
    }
  }
}
