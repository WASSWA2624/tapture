import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// The only sanctioned home for keys and credentials (FE-SEC-01).
///
/// Tests pass [SecureStorage.fake] a map so they never open the plugin
/// (FE-STR-11, FE-TEST-03). Nothing ships with a provider key (FE-SEC-02).
abstract interface class SecureStorage {
  /// Wraps the platform Keystore / Keychain.
  factory SecureStorage() {
    const FlutterSecureStorage plugin = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    return _SecureStorage(
      write: (SecretKey key, String value) {
        return plugin.write(key: _name(key), value: value);
      },
      read: (SecretKey key) {
        return plugin.read(key: _name(key));
      },
      delete: (SecretKey key) {
        return plugin.delete(key: _name(key));
      },
      clear: () => plugin.deleteAll(),
    );
  }

  /// A hand-written stand-in driven by [backing], so a restart is a new
  /// instance over the same map. [preferences] and [database] are debug
  /// witnesses: a secret value must never appear in either.
  factory SecureStorage.fake({
    required Map<SecretKey, String> backing,
    Map<String, String>? preferences,
    Map<String, String>? database,
  }) {
    return _SecureStorage(
      write: (SecretKey key, String value) async {
        backing[key] = value;
      },
      read: (SecretKey key) async {
        return backing[key];
      },
      delete: (SecretKey key) async {
        backing.remove(key);
      },
      clear: () async {
        backing.clear();
      },
      preferences: preferences,
      database: database,
    );
  }

  /// Writes [value] under [key]. The value is never logged.
  Future<Result<void>> putSecret(SecretKey key, String value);

  /// The stored value, or null when [key] has never been written.
  Future<Result<String?>> readSecret(SecretKey key);

  /// Removes every [SecretKey], leaving no readable residue.
  Future<void> deleteAll();
}

/// Closed set of secret names. Arbitrary strings cannot be stored.
enum SecretKey {
  /// Salt for the optional app-lock PIN.
  pinSalt,

  /// Salted hash of the optional app-lock PIN.
  pinHash,

  /// PIN attempt backoff so a restart does not reset the counter.
  pinBackoff,

  /// Device-held provider credential, the permitted exception (FE-SEC-02).
  providerCredential,

  /// Optional change-relay project identifier.
  relayProject,

  /// Cloud destination access token.
  cloudAccess,

  /// Cloud destination refresh token.
  cloudRefresh,
}

final class _SecureStorage implements SecureStorage {
  _SecureStorage({
    required this._write,
    required this._read,
    required this._delete,
    required this._clear,
    this._preferences,
    this._database,
  });

  final _Write _write;
  final _Read _read;
  final _Delete _delete;
  final _Clear _clear;
  final Map<String, String>? _preferences;
  final Map<String, String>? _database;

  @override
  Future<Result<void>> putSecret(SecretKey key, String value) async {
    try {
      await _write(key, value);
      _debugAssertIsolated(value);
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        error is Failure
            ? error
            : const StorageFailure(
                message: 'The secret could not be saved on this device.',
                recoveryAction: 'Try again.',
              ),
      );
    }
  }

  @override
  Future<Result<String?>> readSecret(SecretKey key) async {
    try {
      return Success<String?>(await _read(key));
    } on Object catch (error) {
      return FailureResult<String?>(
        error is Failure
            ? error
            : const StorageFailure(
                message: 'The secret could not be read on this device.',
                recoveryAction: 'Try again.',
              ),
      );
    }
  }

  @override
  Future<void> deleteAll() async {
    for (final SecretKey key in SecretKey.values) {
      try {
        await _delete(key);
      } on Object {
        // The contract is void; keep clearing the rest of the set.
      }
    }
    try {
      await _clear();
    } on Object {
      // Same: every SecretKey is already deleted above.
    }
  }

  void _debugAssertIsolated(String value) {
    assert(() {
      final Map<String, String>? preferences = _preferences;
      final Map<String, String>? database = _database;
      if (preferences != null) {
        assert(
          !preferences.values.contains(value),
          'secret value passed to the preferences store',
        );
      }
      if (database != null) {
        assert(
          !database.values.contains(value),
          'secret value passed to the database',
        );
      }
      return true;
    }());
  }
}

typedef _Write = Future<void> Function(SecretKey key, String value);
typedef _Read = Future<String?> Function(SecretKey key);
typedef _Delete = Future<void> Function(SecretKey key);
typedef _Clear = Future<void> Function();

String _name(SecretKey key) {
  switch (key) {
    case SecretKey.pinSalt:
      return AppConstants.secrets.pinSalt;
    case SecretKey.pinHash:
      return AppConstants.secrets.pinHash;
    case SecretKey.pinBackoff:
      return AppConstants.secrets.pinBackoff;
    case SecretKey.providerCredential:
      return AppConstants.secrets.providerCredential;
    case SecretKey.relayProject:
      return AppConstants.secrets.relayProject;
    case SecretKey.cloudAccess:
      return AppConstants.secrets.cloudAccess;
    case SecretKey.cloudRefresh:
      return AppConstants.secrets.cloudRefresh;
  }
}
