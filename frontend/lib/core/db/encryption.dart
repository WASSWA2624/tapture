import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3_raw;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/authenticated_file_cipher.dart';
import 'package:tapture/core/security/secure_storage.dart';

part 'encryption_codec.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [DatabaseEncryption].
typedef Encryption = DatabaseEncryption;

/// Typed confirmation that turns encryption off. Anything else is refused.
const String kDisableEncryptionConfirmation = 'DISABLE ENCRYPTION';

/// Optional at-rest encryption of the SQLite file. The key lives only in
/// [SecureStorage]; a missing key is a recoverable failure, never a wipe.
abstract interface class DatabaseEncryption {
  /// Operates on the database files under [directory].
  factory DatabaseEncryption({
    required SecureStorage storage,
    required Directory directory,
  }) = _DatabaseEncryption;

  /// Whether a verified encrypted database is what will be opened.
  Future<Result<bool>> isEnabled();

  /// Encrypts the plain file in place, reporting [onProgress] from 0 to 1.
  Future<Result<void>> enable({required void Function(double) onProgress});

  /// Decrypts after [confirmation] matches [kDisableEncryptionConfirmation].
  Future<Result<void>> disable({required String confirmation});
}

/// File executor that decrypts when ciphertext is present, then re-encrypts
/// on close so the working SQLite file is not what remains at rest. With a
/// key and encryption on (a ciphertext exists, or [databaseKeyAtLaunch]
/// turned it on for a fresh install), the working file is re-encrypted on
/// close. Every connection runs on a background isolate, so a large import
/// never blocks the UI thread (FE-PERF-02).
Future<QueryExecutor> resolveFileExecutor({
  required Directory directory,
  String? encryptionKey,
}) async {
  final File working = File('${directory.path}/$_plainName');
  final File enc = File('${directory.path}/$_encName');
  final String? key = encryptionKey;
  if ((enc.existsSync() || _encryptionOn(directory)) &&
      (key == null || key.isEmpty)) {
    // A crash may leave the working file beside its encrypted snapshot. The
    // leftover is still protected by the same key requirement.
    throw StorageFailure(
      localizedMessage: Copy.messages.failureTheDatabaseIsEncryptedAndTheKey,
      localizedRecovery: Copy.messages.failureRestoreTheKeyFromABackupThen,
    );
  }
  if (enc.existsSync() && !_looksLikeSqlite(working)) {
    if (key == null || key.isEmpty) {
      throw StorageFailure(
        localizedMessage: Copy.messages.failureTheDatabaseIsEncryptedAndTheKey,
        localizedRecovery: Copy.messages.failureRestoreTheKeyFromABackupThen,
      );
    }
    _deleteFile(working);
    final Result<void> decrypted = await _cryptFile(
      source: enc,
      dest: working,
      key: key,
      encrypt: false,
    );
    if (decrypted is FailureResult<void> || !_looksLikeSqlite(working)) {
      _deleteFile(working);
      throw StorageFailure(
        localizedMessage:
            Copy.messages.failureTheDatabaseKeyIsMissingOrUnreadable,
        localizedRecovery: Copy.messages.failureRestoreTheKeyFromABackupThen,
      );
    }
    return _reencrypting(working: working, enc: enc, key: key);
  }
  if (key != null &&
      key.isNotEmpty &&
      (enc.existsSync() || _encryptionOn(directory))) {
    if (enc.existsSync()) {
      final Result<void> verified = await runIsolate(_verifyEncryptionKey, (
        path: enc.path,
        key: key,
      ));
      if (verified is FailureResult<void>) {
        throw _lostKey;
      }
    }
    return _reencrypting(working: working, enc: enc, key: key);
  }
  return NativeDatabase.createInBackground(working, setup: _configureSqlite);
}

/// The key the app database opens with at launch, read from [storage].
///
/// An existing key is returned as it is, so an encrypted database reopens.
/// A fresh install — no database file under [directory] yet — gets a new key
/// here and has encryption turned on, so its file is encrypted at rest from
/// the first close. An existing unencrypted database gets no key and keeps
/// opening as it is. A key that cannot be read or stored opens without one:
/// never a new key over one that was lost, and never a wipe.
Future<String?> databaseKeyAtLaunch({
  required SecureStorage storage,
  required Directory directory,
}) async {
  final Result<String?> stored = await storage.readSecret(
    SecretKey.databaseEncryption,
  );
  switch (stored) {
    case FailureResult<String?>():
      return null;
    case Success<String?>(:final String? value):
      if (value != null && value.isNotEmpty) {
        return value;
      }
  }
  final bool fresh =
      !File('${directory.path}/$_plainName').existsSync() &&
      !File('${directory.path}/$_encName').existsSync();
  if (!fresh) {
    return null;
  }
  final String key = _newKey();
  final Result<void> written = await storage.putSecret(
    SecretKey.databaseEncryption,
    key,
  );
  if (written is FailureResult<void>) {
    return null;
  }
  File('${directory.path}/$_stateName').writeAsStringSync(_stateEnabled);
  return key;
}

QueryExecutor _reencrypting({
  required File working,
  required File enc,
  required String key,
}) {
  return NativeDatabase.createInBackground(
    working,
    setup: _configureSqlite,
  ).interceptWith(_ReencryptOnClose(working: working, enc: enc, key: key));
}

/// Whether the recorded state under [directory] says encryption is on.
bool _encryptionOn(Directory directory) {
  final File state = File('${directory.path}/$_stateName');
  try {
    return state.existsSync() && state.readAsStringSync() == _stateEnabled;
  } on FileSystemException {
    return false;
  }
}

final class _DatabaseEncryption implements DatabaseEncryption {
  _DatabaseEncryption({required this.storage, required this.directory});

  final SecureStorage storage;
  final Directory directory;

  File get _plain => File('${directory.path}/$_plainName');
  File get _enc => File('${directory.path}/$_encName');
  File get _partial => File('${directory.path}/$_partialName');
  File get _bak => File('${directory.path}/$_bakName');
  File get _state => File('${directory.path}/$_stateName');

  @override
  Future<Result<bool>> isEnabled() async {
    return Success<bool>(
      _encryptionOn(directory) ||
          (_enc.existsSync() && _looksLikeEncrypted(_enc)),
    );
  }

  @override
  Future<Result<void>> enable({
    required void Function(double) onProgress,
  }) async {
    onProgress(0);
    final Result<bool> enabled = await isEnabled();
    if (enabled is Success<bool> && enabled.value) {
      onProgress(1);
      return const Success<void>(null);
    }
    final Result<String> key = await _ensureKey();
    if (key is FailureResult<String>) {
      return FailureResult<void>(key.failure);
    }
    onProgress(0.05);
    _writeState('enabling');
    return _finishEnable(key: key.getOrElse(() => ''), onProgress: onProgress);
  }

  @override
  Future<Result<void>> disable({required String confirmation}) async {
    if (confirmation != kDisableEncryptionConfirmation) {
      return FailureResult<void>(
        ValidationFailure(
          localizedMessage:
              Copy.messages.failureTypeDISABLEENCRYPTIONToTurnEncryptionOff,
          localizedRecovery:
              Copy.messages.failureEnterTheConfirmationExactlyThenTryAgain,
        ),
      );
    }
    final Result<String?> stored = await storage.readSecret(
      SecretKey.databaseEncryption,
    );
    if (stored is FailureResult<String?>) {
      return FailureResult<void>(stored.failure);
    }
    final String? key = stored.getOrElse(() => null);
    if (key == null || key.isEmpty) {
      return FailureResult<void>(_lostKey);
    }
    if (_looksLikeSqlite(_plain) || !_enc.existsSync()) {
      return _clearEncryption(keyHeld: true);
    }
    _writeState('disabling');
    final File decoded = File('${_plain.path}.partial');
    _deleteFile(decoded);
    final Result<void> decrypted = await _cryptFile(
      source: _enc,
      dest: decoded,
      key: key,
      encrypt: false,
    );
    if (decrypted is FailureResult<void> || !_looksLikeSqlite(decoded)) {
      _deleteFile(decoded);
      return FailureResult<void>(_lostKey);
    }
    _checkpoint(decoded);
    if (_plain.existsSync()) {
      _deleteFile(_plain);
    }
    decoded.renameSync(_plain.path);
    return _clearEncryption(keyHeld: true);
  }

  Future<Result<String>> _ensureKey() async {
    final Result<String?> stored = await storage.readSecret(
      SecretKey.databaseEncryption,
    );
    if (stored is FailureResult<String?>) {
      return FailureResult<String>(stored.failure);
    }
    final String? existing = stored.getOrElse(() => null);
    if (existing != null && existing.isNotEmpty) {
      return Success<String>(existing);
    }
    final String key = _newKey();
    final Result<void> written = await storage.putSecret(
      SecretKey.databaseEncryption,
      key,
    );
    if (written is FailureResult<void>) {
      return FailureResult<String>(written.failure);
    }
    return Success<String>(key);
  }

  Future<Result<void>> _finishEnable({
    required String key,
    required void Function(double) onProgress,
  }) async {
    if (_enc.existsSync() && _looksLikeEncrypted(_enc)) {
      final Result<void> resumed = await _resumeVerifiedEnc(key);
      if (resumed is Success<void>) {
        onProgress(1);
        return resumed;
      }
      _deleteFile(_enc);
    }
    if (!_looksLikeSqlite(_plain)) {
      return FailureResult<void>(
        StorageFailure(
          localizedMessage: Copy.messages.failureThereIsNoDatabaseToEncrypt,
          localizedRecovery: Copy.messages.failureOpenTheAppOnceSoADatabase,
        ),
      );
    }
    _checkpoint(_plain);
    _deleteFile(_partial);
    final Map<String, int> before = _rowCounts(_plain);
    final Result<void> copied = await _cryptFile(
      source: _plain,
      dest: _partial,
      key: key,
      encrypt: true,
      onProgress: (double p) => onProgress(0.1 + p * 0.7),
    );
    if (copied is FailureResult<void>) {
      _deleteFile(_partial);
      return FailureResult<void>(
        StorageFailure(
          localizedMessage: Copy.messages.failureTheDatabaseCouldNotBeEncrypted,
          localizedRecovery: Copy.messages.failureFreeUpSpaceThenTryAgain,
        ),
      );
    }
    if (!await _partialMatches(key, before)) {
      _deleteFile(_partial);
      return FailureResult<void>(
        StorageFailure(
          localizedMessage: Copy.messages.failureTheEncryptedCopyDidNotMatchThe,
          localizedRecovery:
              Copy.messages.failureTryEncryptingAgainTheOriginalDatabaseWas,
        ),
      );
    }
    onProgress(0.9);
    _plain.copySync(_bak.path);
    _deleteFile(_enc);
    _partial.renameSync(_enc.path);
    _deleteFile(_plain);
    _deleteSidecars(_plain);
    _deleteFile(_bak);
    _writeState(_stateEnabled);
    onProgress(1);
    return const Success<void>(null);
  }

  Future<Result<void>> _resumeVerifiedEnc(String key) async {
    if (_looksLikeSqlite(_plain)) {
      _checkpoint(_plain);
      if (!await _encMatches(key, _rowCounts(_plain))) {
        return FailureResult<void>(_lostKey);
      }
      _deleteFile(_plain);
      _deleteSidecars(_plain);
    }
    _deleteFile(_bak);
    _deleteFile(_partial);
    _writeState(_stateEnabled);
    return const Success<void>(null);
  }

  Future<bool> _partialMatches(String key, Map<String, int> before) {
    return _fileMatches(_partial, key, before);
  }

  Future<bool> _encMatches(String key, Map<String, int> before) {
    return _fileMatches(_enc, key, before);
  }

  Future<bool> _fileMatches(
    File ciphertext,
    String key,
    Map<String, int> before,
  ) async {
    final File verify = File('${_plain.path}.verify');
    _deleteFile(verify);
    final Result<void> decoded = await _cryptFile(
      source: ciphertext,
      dest: verify,
      key: key,
      encrypt: false,
    );
    final bool ok =
        decoded is Success<void> &&
        _looksLikeSqlite(verify) &&
        _sameCounts(before, _rowCounts(verify));
    _deleteFile(verify);
    return ok;
  }

  Future<Result<void>> _clearEncryption({required bool keyHeld}) async {
    _deleteFile(_enc);
    _deleteFile(_partial);
    _deleteFile(_bak);
    if (keyHeld) {
      final Result<void> removed = await storage.deleteSecret(
        SecretKey.databaseEncryption,
      );
      if (removed is FailureResult<void>) {
        return removed;
      }
    }
    _writeState('disabled');
    return const Success<void>(null);
  }

  void _writeState(String value) {
    _state.writeAsStringSync(value);
  }
}

final class _ReencryptOnClose extends QueryInterceptor {
  _ReencryptOnClose({
    required this.working,
    required this.enc,
    required this.key,
  });

  final File working;
  final File enc;
  final String key;

  @override
  Future<void> close(QueryExecutor inner) async {
    await inner.close();
    if (!_looksLikeSqlite(working)) {
      return;
    }
    _checkpoint(working);
    final File partial = File('${enc.path}.partial');
    _deleteFile(partial);
    final Map<String, int> before = _rowCounts(working);
    final Result<void> copied = await _cryptFile(
      source: working,
      dest: partial,
      key: key,
      encrypt: true,
    );
    if (copied is FailureResult<void>) {
      _deleteFile(partial);
      throw StorageFailure(
        localizedMessage: Copy.messages.failureTheDatabaseCouldNotBeEncrypted,
        localizedRecovery: Copy.messages.failureFreeUpSpaceThenTryAgain,
      );
    }
    final File verify = File('${working.path}.verify');
    _deleteFile(verify);
    final Result<void> decoded = await _cryptFile(
      source: partial,
      dest: verify,
      key: key,
      encrypt: false,
    );
    final bool matched =
        decoded is Success<void> &&
        _looksLikeSqlite(verify) &&
        _sameCounts(before, _rowCounts(verify));
    _deleteFile(verify);
    if (!matched) {
      _deleteFile(partial);
      throw StorageFailure(
        localizedMessage: Copy.messages.failureTheEncryptedCopyDidNotMatchThe,
        localizedRecovery:
            Copy.messages.failureKeepTheWorkingDatabaseFreeUpSpace,
      );
    }
    _deleteFile(enc);
    partial.renameSync(enc.path);
    _deleteFile(working);
    _deleteSidecars(working);
  }
}

final StorageFailure _lostKey = StorageFailure(
  localizedMessage: Copy.messages.failureTheDatabaseKeyIsMissingOrUnreadable,
  localizedRecovery: Copy.messages.failureRestoreTheKeyFromABackupThe,
);
