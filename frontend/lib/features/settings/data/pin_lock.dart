import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/hash/hashing_service.dart';
import 'package:tapture/core/security/biometric_prompt.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/app_lock.dart';
import '../domain/setting_keys.dart';
import 'biometric_lock.dart';
import 'settings_store.dart';

/// Atomic salted PIN credential and persisted backoff in [SecureStorage].
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
    Duration? storageTimeout,
  }) : this._(
         storage,
         clock,
         biometrics ?? BiometricLock(),
         settings,
         storageTimeout ?? AppConstants.lock.storageTimeout,
       );

  PinLock._(
    this._storage,
    this._clock,
    this._biometrics,
    this._settings,
    this._storageTimeout,
  );

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
      biometrics: biometrics ?? BiometricLock.fake(),
      settings: settings,
    );
    lock._enabled = backing[SecretKey.pinHash]?.isNotEmpty ?? false;
    lock._ready =
        (!lock._enabled ||
            lock._decodeCredential(
                  backing[SecretKey.pinHash],
                  legacySalt: backing[SecretKey.pinSalt],
                ) !=
                null) &&
        lock._decodeBackoff(backing[SecretKey.pinBackoff]);
    return lock;
  }

  final SecureStorage _storage;
  final Clock _clock;
  final BiometricLock _biometrics;
  final SettingsStore? _settings;
  final Duration _storageTimeout;

  bool _enabled = true;
  bool _ready = false;
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
    final List<Result<String?>> loaded = await Future.wait(
      <Future<Result<String?>>>[
        _read(SecretKey.pinHash),
        _read(SecretKey.pinBackoff),
      ],
    );
    final Result<String?> hash = loaded[0];
    final Result<String?> backoff = loaded[1];
    _ready = false;
    if (hash is FailureResult<String?>) {
      _enabled = true;
      return;
    }
    _enabled = hash.getOrThrow()?.isNotEmpty ?? false;
    if (!_enabled) {
      _decodeBackoff(null);
      _ready = true;
    } else if (backoff is Success<String?>) {
      _ready =
          await _loadCredential(hash.getOrThrow()) != null &&
          _decodeBackoff(backoff.value);
    }
  }

  @override
  Future<Result<void>> setPin(String pin) async {
    if (!isAppLockPin(pin)) {
      return FailureResult<void>(
        ValidationFailure(
          message: Copy.appLockPinLength,
          localizedMessage: Copy.messages.appLockPinLength,
          recoveryAction: Copy.appLockPinLength,
          localizedRecovery: Copy.messages.appLockPinLength,
        ),
      );
    }
    final String salt = _newSalt();
    final String hash = _hash(salt, pin);
    // Salt and digest replace the previous credential in one platform write.
    // An interrupted or refused replacement cannot pair an old digest with a
    // new salt and permanently lock out the operator's existing PIN.
    final Result<void> written = await _storage.putSecret(
      SecretKey.pinHash,
      jsonEncode(<String, Object>{'version': 1, 'salt': salt, 'hash': hash}),
    );
    if (written is FailureResult<void>) {
      return written;
    }
    // Old separate salts are no longer used; a failed cleanup is harmless.
    await _storage.deleteSecret(SecretKey.pinSalt);
    await _storage.deleteSecret(SecretKey.pinBackoff);
    _failures = 0;
    _until = null;
    _enabled = true;
    _ready = true;
    await _writeFlag(true);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> removePin(String currentPin) async {
    final LockAttempt attempt = await unlockWithPin(currentPin);
    switch (attempt) {
      case LockAttempt.unlocked:
        final Result<void> deleted = await _storage.deleteSecret(
          SecretKey.pinHash,
        );
        if (deleted is FailureResult<void>) {
          return deleted;
        }
        await _storage.deleteSecret(SecretKey.pinSalt);
        await _storage.deleteSecret(SecretKey.pinBackoff);
        _failures = 0;
        _until = null;
        _enabled = false;
        _ready = true;
        await _writeFlag(false);
        return const Success<void>(null);
      case LockAttempt.lockedOut:
        return FailureResult<void>(
          ValidationFailure(
            message: Copy.appLockWait(remainingBackoff),
            localizedMessage: Copy.messages.appLockWait(remainingBackoff),
            recoveryAction: Copy.appLockWait(remainingBackoff),
            localizedRecovery: Copy.messages.appLockWait(remainingBackoff),
          ),
        );
      case LockAttempt.wrong:
      case LockAttempt.unavailable:
        return FailureResult<void>(
          ValidationFailure(
            message: Copy.appLockWrongPin,
            localizedMessage: Copy.messages.appLockWrongPin,
            recoveryAction: Copy.appLockPinLength,
            localizedRecovery: Copy.messages.appLockPinLength,
          ),
        );
    }
  }

  @override
  Future<LockAttempt> unlockWithPin(String pin) async {
    if (!_ready) {
      await hydrate();
    }
    if (!_enabled || !_ready) {
      return LockAttempt.unavailable;
    }
    if (remainingBackoff > Duration.zero) {
      return LockAttempt.lockedOut;
    }
    final Result<String?> hash = await _read(SecretKey.pinHash);
    if (hash is FailureResult<String?>) {
      return LockAttempt.unavailable;
    }
    final _PinCredential? credential = await _loadCredential(hash.getOrThrow());
    if (credential == null) {
      _ready = false;
      return LockAttempt.unavailable;
    }
    if (_hash(credential.salt, pin) == credential.hash) {
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
    if (!_enabled || !_ready) {
      return Future<bool>.value(false);
    }
    return _biometrics.isAvailable();
  }

  @override
  Future<LockAttempt> unlockWithBiometrics({
    String? localizedReason,
    BiometricPrompt? prompt,
  }) async {
    if (!_ready) {
      await hydrate();
    }
    if (!_enabled || !_ready) {
      return LockAttempt.unavailable;
    }
    if (!await _biometrics.isAvailable()) {
      return LockAttempt.unavailable;
    }
    final LockAttempt attempt = await _biometrics.unlock(
      localizedReason: localizedReason,
      prompt: prompt,
    );
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

  bool _decodeBackoff(String? raw) {
    if (raw == null || raw.isEmpty) {
      _failures = 0;
      _until = null;
      return true;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return false;
      }
      final Object? count = decoded['count'];
      final Object? until = decoded['until'];
      if (count is! int || count < 0 || until is! String) {
        return false;
      }
      final DateTime? parsed = DateTime.tryParse(until)?.toUtc();
      if (parsed == null) {
        return false;
      }
      _failures = count;
      _until = parsed;
      return true;
    } on FormatException {
      return false;
    }
  }

  Future<Result<String?>> _read(SecretKey key) async {
    try {
      return await _storage.readSecret(key).timeout(_storageTimeout);
    } on Object {
      return FailureResult<String?>(
        StorageFailure(
          localizedMessage: Copy.messages.appLockStorageUnavailable,
          localizedRecovery: Copy.messages.appLockStorageRecovery,
        ),
      );
    }
  }

  Future<_PinCredential?> _loadCredential(String? stored) async {
    // Legacy reads remain supported without rewriting authentication evidence.
    if (stored != null && _hashPattern.hasMatch(stored)) {
      final Result<String?> salt = await _read(SecretKey.pinSalt);
      if (salt is FailureResult<String?>) {
        return null;
      }
      return _decodeCredential(stored, legacySalt: salt.getOrThrow());
    }
    return _decodeCredential(stored);
  }

  _PinCredential? _decodeCredential(String? stored, {String? legacySalt}) {
    if (stored == null || stored.length > 512) {
      return null;
    }
    try {
      String? salt = legacySalt;
      String hash = stored;
      if (!_hashPattern.hasMatch(stored)) {
        final Object? decoded = jsonDecode(stored);
        if (decoded case {
          'version': final int version,
          'salt': final String savedSalt,
          'hash': final String savedHash,
        } when version == 1) {
          salt = savedSalt;
          hash = savedHash;
        } else {
          return null;
        }
      }
      if (salt == null ||
          salt.length > 128 ||
          base64Decode(salt).length != AppConstants.lock.saltBytes ||
          !_hashPattern.hasMatch(hash)) {
        return null;
      }
      return (salt: salt, hash: hash);
    } on FormatException {
      return null;
    }
  }

  static final RegExp _hashPattern = RegExp(r'^[0-9a-f]{64}$');

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

typedef _PinCredential = ({String salt, String hash});

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
