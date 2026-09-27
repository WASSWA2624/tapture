import 'dart:convert';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';

/// Credential values for cloud destinations, keyed by credential ref.
///
/// The database stores only the ref. Access material sits under
/// [SecretKey.cloudAccess] and refresh tokens under [SecretKey.cloudRefresh],
/// each a JSON object. A value is never logged and never written beside the row.
abstract interface class DestinationSecrets {
  /// Stores credentials in [storage].
  factory DestinationSecrets(SecureStorage storage) = _SecureDestinationSecrets;

  /// Writes [payload] for [ref], replacing any previous payload.
  Future<Result<void>> put(String ref, String payload);

  /// The payload for [ref], or null when it was never saved.
  Future<Result<String?>> read(String ref);

  /// Removes [ref] from access and refresh storage.
  Future<Result<void>> delete(String ref);

  /// Writes the refresh token for [ref].
  Future<Result<void>> putRefresh(String ref, String token);

  /// The refresh token for [ref], or null.
  Future<Result<String?>> readRefresh(String ref);
}

final class _SecureDestinationSecrets implements DestinationSecrets {
  _SecureDestinationSecrets(this._storage);

  final SecureStorage _storage;

  @override
  Future<Result<void>> put(String ref, String payload) {
    return _write(SecretKey.cloudAccess, ref, payload);
  }

  @override
  Future<Result<String?>> read(String ref) {
    return _read(SecretKey.cloudAccess, ref);
  }

  @override
  Future<Result<void>> delete(String ref) async {
    final Result<void> access = await _remove(SecretKey.cloudAccess, ref);
    if (access is FailureResult<void>) {
      return access;
    }
    return _remove(SecretKey.cloudRefresh, ref);
  }

  @override
  Future<Result<void>> putRefresh(String ref, String token) {
    return _write(SecretKey.cloudRefresh, ref, token);
  }

  @override
  Future<Result<String?>> readRefresh(String ref) {
    return _read(SecretKey.cloudRefresh, ref);
  }

  Future<Result<Map<String, String>>> _map(SecretKey key) async {
    final Result<String?> raw = await _storage.readSecret(key);
    return raw.fold(FailureResult<Map<String, String>>.new, (String? value) {
      if (value == null || value.isEmpty) {
        return const Success<Map<String, String>>(<String, String>{});
      }
      try {
        final Object? decoded = jsonDecode(value);
        if (decoded is! Map) {
          return const Success<Map<String, String>>(<String, String>{});
        }
        return Success<Map<String, String>>(<String, String>{
          for (final MapEntry<Object?, Object?> entry in decoded.entries)
            '${entry.key}': '${entry.value}',
        });
      } on FormatException {
        return const FailureResult<Map<String, String>>(
          CorruptionFailure(
            message: 'The saved sign-in could not be read.',
            recoveryAction: 'Remove the destination and add it again.',
          ),
        );
      }
    });
  }

  Future<Result<void>> _write(SecretKey key, String ref, String payload) async {
    final Result<Map<String, String>> current = await _map(key);
    if (current is FailureResult<Map<String, String>>) {
      return FailureResult<void>(current.failure);
    }
    final Map<String, String> next = Map<String, String>.of(
      (current as Success<Map<String, String>>).value,
    );
    next[ref] = payload;
    return _storage.putSecret(key, jsonEncode(next));
  }

  Future<Result<String?>> _read(SecretKey key, String ref) async {
    final Result<Map<String, String>> current = await _map(key);
    return current.map((Map<String, String> values) => values[ref]);
  }

  Future<Result<void>> _remove(SecretKey key, String ref) async {
    final Result<Map<String, String>> current = await _map(key);
    if (current is FailureResult<Map<String, String>>) {
      return FailureResult<void>(current.failure);
    }
    final Map<String, String> next = Map<String, String>.of(
      (current as Success<Map<String, String>>).value,
    );
    next.remove(ref);
    if (next.isEmpty) {
      return _storage.deleteSecret(key);
    }
    return _storage.putSecret(key, jsonEncode(next));
  }
}
