import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';

import 'destination_secret_lease.dart';

/// Credential and upload-session values in secure storage, never in history.
abstract interface class DestinationSecrets {
  /// Creates the secure store. Wrappers serialize mutations to the shared maps.
  factory DestinationSecrets(SecureStorage storage, {Clock? clock}) =
      _SecureDestinationSecrets;

  /// Replaces sign-in and invalidates older worker leases.
  Future<Result<void>> put(String ref, String payload);

  /// The saved sign-in, or null.
  Future<Result<String?>> read(String ref);

  /// Removes sign-in, refresh tokens and every upload session for [ref].
  Future<Result<void>> forget(String ref);

  /// Stores a refresh token for the current sign-in.
  Future<Result<void>> putRefresh(String ref, String token);

  /// The saved refresh token, or null.
  Future<Result<String?>> readRefresh(String ref);

  /// Takes a consistent snapshot and prunes abandoned secure checkpoints.
  Future<Result<DestinationSecretLease>> lease(String ref, String sessionKey);

  /// Persists a worker write only while its sign-in generation still exists.
  /// [session] selects the lease's session slot; null clears that slot.
  Future<Result<void>> putLeased(
    DestinationSecretLease lease, {
    required String? value,
    bool refresh = false,
    bool session = false,
  });
}

final class _SecureDestinationSecrets implements DestinationSecrets {
  _SecureDestinationSecrets(this._storage, {Clock? clock})
    : _clock = clock ?? const SystemClock();

  final SecureStorage _storage;
  final Clock _clock;
  final Random _random = Random.secure();
  static Future<void> _tail = Future<void>.value();
  static const String _generationPrefix = '@generation:';
  static const String _sessionPrefix = '@session:';

  Future<Result<T>> _locked<T>(Future<T> Function() operation) async {
    final Future<void> previous = _tail;
    final Completer<void> release = Completer<void>();
    _tail = release.future;
    await previous;
    try {
      return await Result.captureAsync<T>(operation);
    } finally {
      release.complete();
    }
  }

  @override
  Future<Result<void>> put(String ref, String payload) => _locked(() async {
    final Map<String, String> access = await _map(SecretKey.cloudAccess);
    access[ref] = payload;
    access[_generationPrefix + ref] = base64UrlEncode(
      List<int>.generate(24, (_) => _random.nextInt(256)),
    );
    _removeSessions(access, ref);
    await _save(SecretKey.cloudAccess, access);
    final Map<String, String> refresh = await _map(SecretKey.cloudRefresh);
    refresh.remove(ref);
    await _save(SecretKey.cloudRefresh, refresh);
  });

  @override
  Future<Result<String?>> read(String ref) =>
      _locked(() async => (await _map(SecretKey.cloudAccess))[ref]);

  @override
  Future<Result<String?>> readRefresh(String ref) =>
      _locked(() async => (await _map(SecretKey.cloudRefresh))[ref]);

  @override
  Future<Result<void>> putRefresh(String ref, String token) =>
      _locked(() async {
        final Map<String, String> access = await _map(SecretKey.cloudAccess);
        if (!access.containsKey(ref)) {
          throw _removed;
        }
        final Map<String, String> refresh = await _map(SecretKey.cloudRefresh);
        refresh[ref] = token;
        await _save(SecretKey.cloudRefresh, refresh);
      });

  @override
  Future<Result<void>> forget(String ref) => _locked(() async {
    final Map<String, String> access = await _map(SecretKey.cloudAccess);
    access.remove(ref);
    access.remove(_generationPrefix + ref);
    _removeSessions(access, ref);
    // Invalidate the lease first, even if deleting refresh material fails.
    await _save(SecretKey.cloudAccess, access);
    final Map<String, String> refresh = await _map(SecretKey.cloudRefresh);
    refresh.remove(ref);
    await _save(SecretKey.cloudRefresh, refresh);
  });

  @override
  Future<Result<DestinationSecretLease>> lease(String ref, String sessionKey) =>
      _locked(() async {
        final Map<String, String> access = await _map(SecretKey.cloudAccess);
        final String generationKey = _generationPrefix + ref;
        // Upgrade legacy saved credentials before handing them to a worker.
        if (access[ref] != null && access[generationKey] == null) {
          access[generationKey] = base64UrlEncode(
            List<int>.generate(24, (_) => _random.nextInt(256)),
          );
        }
        _prune(access, ref);
        await _save(SecretKey.cloudAccess, access);
        final Map<String, String> refresh = await _map(SecretKey.cloudRefresh);
        final String key = _sessionSlot(ref, sessionKey);
        return DestinationSecretLease(
          ref: ref,
          generation: access[generationKey] ?? '',
          sessionKey: key,
          access: access[ref],
          refresh: refresh[ref],
          session: _sessionValue(access[key]),
        );
      });

  @override
  Future<Result<void>> putLeased(
    DestinationSecretLease lease, {
    required String? value,
    bool refresh = false,
    bool session = false,
  }) => _locked(() async {
    final Map<String, String> access = await _map(SecretKey.cloudAccess);
    if (lease.generation.isEmpty ||
        !access.containsKey(lease.ref) ||
        access[_generationPrefix + lease.ref] != lease.generation) {
      throw _removed;
    }
    if (session) {
      if (value == null) {
        access.remove(lease.sessionKey);
      } else {
        access[lease.sessionKey] = jsonEncode(<String, Object>{
          'at': _clock.nowUtc().toIso8601String(),
          'json': value,
        });
      }
      _prune(access, lease.ref, keepKey: lease.sessionKey);
      await _save(SecretKey.cloudAccess, access);
    } else if (refresh) {
      final Map<String, String> tokens = await _map(SecretKey.cloudRefresh);
      if (value == null) {
        tokens.remove(lease.ref);
      } else {
        tokens[lease.ref] = value;
      }
      await _save(SecretKey.cloudRefresh, tokens);
    } else {
      if (value == null) {
        throw _removed;
      }
      access[lease.ref] = value;
      await _save(SecretKey.cloudAccess, access);
    }
  });

  String _sessionSlot(String ref, String key) =>
      '$_sessionPrefix${base64UrlEncode(utf8.encode(ref))}:$key';

  void _removeSessions(Map<String, String> values, String ref) {
    final String prefix = _sessionSlot(ref, '');
    values.removeWhere((String key, _) => key.startsWith(prefix));
  }

  void _prune(Map<String, String> values, String ref, {String? keepKey}) {
    final String prefix = _sessionSlot(ref, '');
    final DateTime cutoff = _clock.nowUtc().subtract(
      AppConstants.cloudUpload.sessionMaxAge,
    );
    final List<({String key, DateTime at})> sessions = [];
    for (final MapEntry<String, String> entry in values.entries) {
      if (!entry.key.startsWith(prefix)) {
        continue;
      }
      DateTime? at;
      try {
        final Object? decoded = jsonDecode(entry.value);
        if (decoded is Map && decoded['at'] is String) {
          at = DateTime.tryParse(decoded['at'] as String);
        }
      } on FormatException {
        // Invalid checkpoints are discarded; credentials remain intact.
      }
      if (at != null && !at.isBefore(cutoff)) {
        sessions.add((key: entry.key, at: at));
      }
    }
    sessions.sort(
      (a, b) => a.key == keepKey
          ? -1
          : b.key == keepKey
          ? 1
          : b.at.compareTo(a.at),
    );
    final Set<String> keep = sessions
        .take(AppConstants.cloudUpload.maxSessions)
        .map((entry) => entry.key)
        .toSet();
    values.removeWhere(
      (String key, _) => key.startsWith(prefix) && !keep.contains(key),
    );
  }

  String? _sessionValue(String? raw) {
    if (raw == null) {
      return null;
    }
    try {
      final Object? value = jsonDecode(raw);
      return value is Map && value['json'] is String
          ? value['json'] as String
          : null;
    } on FormatException {
      return null;
    }
  }

  Future<Map<String, String>> _map(SecretKey key) async {
    final String? raw = (await _storage.readSecret(key)).getOrThrow();
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map &&
          decoded.keys.every((key) => key is String) &&
          decoded.values.every((value) => value is String)) {
        return Map<String, String>.from(decoded);
      }
    } on FormatException {
      // The public API returns the same typed corruption failure.
    }
    throw CorruptionFailure(
      localizedMessage: Copy.messages.failureTheSavedSignInCouldNotBe,
      localizedRecovery: Copy.messages.failureRemoveTheDestinationAndAddItAgain,
    );
  }

  Future<void> _save(SecretKey key, Map<String, String> values) async {
    (await (values.isEmpty
            ? _storage.deleteSecret(key)
            : _storage.putSecret(key, jsonEncode(values))))
        .getOrThrow();
  }
}

final PermissionFailure _removed = PermissionFailure(
  localizedMessage: Copy.messages.failureThisDestinationSignInChangedDuringThe,
  localizedRecovery: Copy.messages.failureReviewTheDestinationAndConfirmANew,
);
