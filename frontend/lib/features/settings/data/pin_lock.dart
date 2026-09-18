import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/hash/hashing_service.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/app_lock.dart';
import '../domain/setting_keys.dart';
import 'biometric_lock.dart';
import 'settings_store.dart';

/// Salted PIN hash and persisted backoff in [SecureStorage].
///
/// The PIN itself is a local argument only. It is never written to the
/// database, the preferences map, an export or a log line (FE-SEC-01).
class PinLock implements AppLock {
  /// Creates a lock over [storage]. Call [hydrate] before the first
  /// redirect so [isEnabled] matches what is already stored.
  PinLock({
    required SecureStorage storage,
    Clock clock = const SystemClock(),
    BiometricLock? biometrics,
    SettingsStore? settings,
  }) : this._(storage, clock, biometrics ?? BiometricLock(), settings);

  PinLock._(this._storage, this._clock, this._biometrics, this._settings);

  /// In-memory stand-in. A restart is a new instance over the same
  /// [backing] (FE-TEST-03).
  factory PinLock.fake({
    required Map<SecretKey, String> backing,
    Map<String, String>? preferences,
    Map<String, String>? database,
    Clock clock = const SystemClock(),
    BiometricLock? biometrics,
    SettingsStore? settings,
  }) {
    final PinLock lock = PinLock(
      storage: SecureStorage.fake(
        backing: backing,
        preferences: preferences,
        database: database,
      ),
      clock: clock,
      biometrics: biometrics,
      settings: settings,
    );
    lock._enabled = backing[SecretKey.pinHash]?.isNotEmpty ?? false;
    lock._decodeBackoff(backing[SecretKey.pinBackoff]);
    return lock;
  }

  final SecureStorage _storage;
  final Clock _clock;
  final BiometricLock _biometrics;
  final SettingsStore? _settings;

  bool _enabled = false;
  int _failures = 0;
  DateTime? _until;

  @override
  bool get isEnabled => _enabled;

  @override
  Duration get remainingBackoff {
    final DateTime? until = _until;
    if (until == null) {
      return Duration.zero;
    }
    final DateTime now = _clock.nowUtc();
    if (!until.isAfter(now)) {
      return Duration.zero;
    }
    return until.difference(now);
  }

  @override
  Future<void> hydrate() async {
    final Result<String?> hash = await _storage.readSecret(SecretKey.pinHash);
    _enabled = hash is Success<String?> && (hash.value?.isNotEmpty ?? false);
    final Result<String?> backoff = await _storage.readSecret(
      SecretKey.pinBackoff,
    );
    if (backoff is Success<String?>) {
      _decodeBackoff(backoff.value);
    }
  }

  @override
  Future<Result<void>> setPin(String pin) async {
    if (!isAppLockPin(pin)) {
      return const FailureResult<void>(
        ValidationFailure(
          message: Copy.appLockPinLength,
          recoveryAction: Copy.appLockPinLength,
        ),
      );
    }
    final String salt = _newSalt();
    final String hash = _hash(salt, pin);
    final Result<void> salted = await _storage.putSecret(
      SecretKey.pinSalt,
      salt,
    );
    if (salted is FailureResult<void>) {
      return salted;
    }
    final Result<void> written = await _storage.putSecret(
      SecretKey.pinHash,
      hash,
    );
    if (written is FailureResult<void>) {
      return written;
    }
    await _storage.deleteSecret(SecretKey.pinBackoff);
    _failures = 0;
    _until = null;
    _enabled = true;
    await _writeFlag(true);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> removePin(String currentPin) async {
    final LockAttempt attempt = await unlockWithPin(currentPin);
    switch (attempt) {
      case LockAttempt.unlocked:
        await _storage.deleteSecret(SecretKey.pinHash);
        await _storage.deleteSecret(SecretKey.pinSalt);
        await _storage.deleteSecret(SecretKey.pinBackoff);
        _failures = 0;
        _until = null;
        _enabled = false;
        await _writeFlag(false);
        return const Success<void>(null);
      case LockAttempt.lockedOut:
        return FailureResult<void>(
          ValidationFailure(
            message: Copy.appLockWait(remainingBackoff),
            recoveryAction: Copy.appLockWait(remainingBackoff),
          ),
        );
      case LockAttempt.wrong:
      case LockAttempt.unavailable:
        return const FailureResult<void>(
          ValidationFailure(
            message: Copy.appLockWrongPin,
            recoveryAction: Copy.appLockPinLength,
          ),
        );
    }
  }

  @override
  Future<LockAttempt> unlockWithPin(String pin) async {
    if (!_enabled) {
      return LockAttempt.unavailable;
    }
    if (remainingBackoff > Duration.zero) {
      return LockAttempt.lockedOut;
    }
    final Result<String?> salt = await _storage.readSecret(SecretKey.pinSalt);
    final Result<String?> hash = await _storage.readSecret(SecretKey.pinHash);
    if (salt is FailureResult<String?> || hash is FailureResult<String?>) {
      return LockAttempt.unavailable;
    }
    final String? saltValue = salt.getOrElse(() => null);
    final String? hashValue = hash.getOrElse(() => null);
    if (saltValue == null ||
        saltValue.isEmpty ||
        hashValue == null ||
        hashValue.isEmpty) {
      return LockAttempt.unavailable;
    }
    if (_hash(saltValue, pin) == hashValue) {
      await _storage.deleteSecret(SecretKey.pinBackoff);
      _failures = 0;
      _until = null;
      return LockAttempt.unlocked;
    }
    await _recordFailure();
    return LockAttempt.wrong;
  }

  @override
  Future<bool> biometricsAvailable() {
    if (!_enabled) {
      return Future<bool>.value(false);
    }
    return _biometrics.isAvailable();
  }

  @override
  Future<LockAttempt> unlockWithBiometrics() async {
    if (!_enabled) {
      return LockAttempt.unavailable;
    }
    if (!await _biometrics.isAvailable()) {
      return LockAttempt.unavailable;
    }
    final LockAttempt attempt = await _biometrics.unlock();
    if (attempt == LockAttempt.unlocked) {
      return LockAttempt.unlocked;
    }
    return attempt;
  }

  Future<void> _recordFailure() async {
    _failures += 1;
    final List<Duration> delays = AppConstants.lock.backoff;
    final int index = _failures - 1 < delays.length
        ? _failures - 1
        : delays.length - 1;
    _until = _clock.nowUtc().add(delays[index]);
    await _storage.putSecret(SecretKey.pinBackoff, _encodeBackoff());
  }

  Future<void> _writeFlag(bool enabled) async {
    final SettingsStore? settings = _settings;
    if (settings == null) {
      return;
    }
    await settings.write(SettingKeys.appLockEnabled, enabled);
  }

  String _encodeBackoff() {
    return jsonEncode(<String, Object?>{
      'count': _failures,
      'until': _until?.toUtc().toIso8601String(),
    });
  }

  void _decodeBackoff(String? raw) {
    _failures = 0;
    _until = null;
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }
      final Object? count = decoded['count'];
      final Object? until = decoded['until'];
      if (count is int) {
        _failures = count;
      }
      if (until is String) {
        _until = DateTime.tryParse(until)?.toUtc();
      }
    } on FormatException {
      _failures = 0;
      _until = null;
    }
  }

  String _newSalt() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(
      AppConstants.lock.saltBytes,
      (int _) => random.nextInt(256),
    );
    return base64Encode(bytes);
  }

  String _hash(String salt, String pin) {
    return HashingService.sha256OfString('$salt$pin');
  }
}

/// Process-wide lock. [main] replaces this with a [PinLock] over
/// platform secure storage so widget tests never open the plugin
/// (FE-TEST-03).
final Provider<AppLock> appLockProvider = Provider<AppLock>((Ref ref) {
  return PinLock.fake(backing: <SecretKey, String>{});
});

/// Injects [lock] so tests never open platform secure storage.
Override appLockOverride(AppLock lock) {
  return appLockProvider.overrideWith((Ref ref) => lock);
}
