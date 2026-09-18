import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

/// Optional lock on launch and resume.
///
/// Only a salted hash of the PIN is stored. The PIN is never written,
/// never logged, and not retained after a comparison (FE-SEC-01).
abstract interface class AppLock {
  /// Whether a PIN hash is stored.
  bool get isEnabled;

  /// Stores a new salted hash and arms the lock.
  Future<Result<void>> setPin(String pin);

  /// Verifies [currentPin] and deletes the hash, salt and backoff.
  Future<Result<void>> removePin(String currentPin);

  /// Compares [pin] to the stored hash, applying the persisted backoff.
  Future<LockAttempt> unlockWithPin(String pin);

  /// Whether the device can offer a biometric path.
  Future<bool> biometricsAvailable();

  /// Tries the biometric path. Failure never reports [LockAttempt.unlocked].
  Future<LockAttempt> unlockWithBiometrics();

  /// Loads whether a hash is already stored. The router guard is
  /// synchronous, so this runs before the first redirect.
  Future<void> hydrate();

  /// Time left in the current backoff, or [Duration.zero].
  Duration get remainingBackoff;
}

/// Outcome of one unlock try.
enum LockAttempt {
  /// The submitted secret matched.
  unlocked,

  /// The submitted secret did not match.
  wrong,

  /// A persisted backoff is still running.
  lockedOut,

  /// No lock is set, or the biometric path cannot run.
  unavailable,
}

final RegExp _digitsOnly = RegExp(r'^\d+$');

/// Whether [pin] is only digits and inside the published length.
bool isAppLockPin(String pin) {
  final int length = pin.length;
  return length >= AppConstants.lock.pinMin &&
      length <= AppConstants.lock.pinMax &&
      _digitsOnly.hasMatch(pin);
}
