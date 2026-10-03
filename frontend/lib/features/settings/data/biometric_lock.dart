import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/biometric_prompt.dart';
import 'package:tapture/core/security/biometric_service.dart';

import '../domain/app_lock.dart';

/// Platform biometric unlock, behind an interface so screens and tests
/// never touch the plugin (FE-STR-11, FE-TEST-03).
///
/// The default uses the maintained SDK through the core security boundary.
/// Tests use [fake] or [wrap] without opening a native dialog.
abstract interface class BiometricLock {
  /// Whether the device has an enrolled biometric.
  Future<bool> isAvailable();

  /// One biometric try. Cancel, failure and an unenrolled device never
  /// report [LockAttempt.unlocked].
  Future<LockAttempt> unlock({
    String? localizedReason,
    BiometricPrompt? prompt,
  });

  /// Production native biometric authentication (task 097).
  factory BiometricLock() = _NativeBiometricLock;

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

final class _NativeBiometricLock implements BiometricLock {
  final BiometricService _service = BiometricService();

  @override
  Future<bool> isAvailable() => _service.isAvailable();

  @override
  Future<LockAttempt> unlock({
    String? localizedReason,
    BiometricPrompt? prompt,
  }) async {
    final Result<bool> result = await _service.authenticate(
      localizedReason: localizedReason ?? Copy.permissionBiometrics,
      prompt: prompt,
    );
    return result.fold(
      (_) => LockAttempt.unavailable,
      (bool accepted) => accepted ? LockAttempt.unlocked : LockAttempt.wrong,
    );
  }
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
  Future<LockAttempt> unlock({
    String? localizedReason,
    BiometricPrompt? prompt,
  }) async => result;
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
  Future<LockAttempt> unlock({
    String? localizedReason,
    BiometricPrompt? prompt,
  }) async {
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
