import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';

import 'backend_api_client.dart';
import 'backend_config.dart';
import 'backend_transport.dart';

/// Durable enrolment and rotating tokens, held only in platform secure storage.
final class BackendSession {
  /// Creates the session. A fake transport and secure store make tests isolated.
  BackendSession({
    required this._storage,
    required this._clock,
    required this.deviceId,
    String initialUrl = '',
    BackendSend? send,
    this.linkAccount,
    bool Function()? offline,
  }) : _offline = offline ?? _online,
       _config = BackendConfig(baseUrl: initialUrl) {
    _send = send ?? BackendTransport(baseUrl: () => _config.baseUrl).send;
  }

  final SecureStorage _storage;
  final Clock _clock;
  final bool Function() _offline;
  late final BackendSend _send;
  final StreamController<BackendConfig> _changes =
      StreamController<BackendConfig>.broadcast();
  BackendConfig _config;
  TokenPair? _tokens;
  Future<bool>? _refreshing;

  /// Stable local device identifier; no provider key exists in this object.
  final String deviceId;

  /// Links the device profile to the account, preserving existing attribution.
  final Future<void> Function(String accountId)? linkAccount;

  /// The latest cached state, readable without waiting for any network call.
  BackendConfig get config => _config;

  /// Emits only after a durable local change or reachability change.
  Stream<BackendConfig> get changes => _changes.stream;

  /// Sends ciphertext with the same token rotation and offline policy as JSON.
  Future<({int status, Uint8List body})> sendBytes({
    required String method,
    required String path,
    Uint8List? body,
    String? idempotencyKey,
    bool json = false,
  }) async {
    if (!canUseBackend) throw const NetworkFailure();
    final BackendTransport transport = BackendTransport(
      baseUrl: () => _config.baseUrl,
    );
    Future<({int status, Uint8List body})> call() => transport.sendBytes(
      method: method,
      path: path,
      body: body,
      token: _tokens!.accessToken,
      idempotencyKey: idempotencyKey,
      json: json,
    );
    try {
      var response = await call();
      if (response.status == 401 && await refresh()) response = await call();
      _reachability(true);
      return response;
    } on Object {
      _reachability(false);
      rethrow;
    }
  }

  /// Whether an online call is permitted by the cached grant and offline switch.
  bool get canUseBackend =>
      !_offline() &&
      _tokens != null &&
      _config.grantValidUntil?.isAfter(_clock.nowUtc()) == true;

  /// Restores the sign-in before the app starts. No network is touched.
  Future<Result<void>> restore() async {
    final Result<String?> saved = await _storage.readSecret(
      SecretKey.backendSession,
    );
    if (saved is FailureResult<String?>) {
      return FailureResult<void>(saved.failure);
    }
    final String? raw = (saved as Success<String?>).value;
    if (raw == null) return const Success<void>(null);
    try {
      final Object? value = jsonDecode(raw);
      if (value is! Map<String, Object?>) throw const FormatException();
      final String? url = value['baseUrl'] as String?;
      final String? access = value['accessToken'] as String?;
      final String? refresh = value['refreshToken'] as String?;
      final Map<String, String?> grants = <String, String?>{};
      final Object? rows = value['grants'];
      if (rows is Map<String, Object?>) {
        for (final MapEntry<String, Object?> entry in rows.entries) {
          if (entry.value == null || entry.value is String) {
            grants[entry.key] = entry.value as String?;
          }
        }
      }
      _tokens = access == null || refresh == null
          ? null
          : (accessToken: access, refreshToken: refresh);
      _config = BackendConfig(
        baseUrl: url ?? _config.baseUrl,
        organisationId: value['organisationId'] as String?,
        accountEmail: value['accountEmail'] as String?,
        accountId: value['accountId'] as String?,
        role: value['role'] as String?,
        aiAvailable: value['aiAvailable'] == true,
        grants: Map<String, String?>.unmodifiable(grants),
        grantValidUntil: DateTime.tryParse(
          value['grantValidUntil'] as String? ?? '',
        ),
        state: _tokens == null
            ? EnrolmentState.notEnrolled
            : EnrolmentState.enrolled,
      );
      if (_config.accountId case final String id) await linkAccount?.call(id);
      return const Success<void>(null);
    } on Object {
      return const FailureResult<void>(
        StorageFailure(
          message: 'The saved sign-in could not be read.',
          recoveryAction:
              'Check the account settings. Your local work is unchanged.',
        ),
      );
    }
  }

  /// Saves an administrator's server address without storing it in preferences.
  Future<Result<void>> configure(String address, String organisationId) async {
    final Uri? uri = Uri.tryParse(address.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return const FailureResult<void>(
        ValidationFailure(
          message: 'Enter the organisation’s HTTPS server address.',
          recoveryAction: 'Check the address with your administrator.',
        ),
      );
    }
    if (_tokens != null &&
        (uri.toString() != _config.baseUrl ||
            organisationId.trim() != _config.organisationId)) {
      return const FailureResult<void>(
        ValidationFailure(
          message: 'Sign out before changing organisation.',
          recoveryAction: 'Keep the current account or sign out first.',
        ),
      );
    }
    if (_tokens != null) return const Success<void>(null);
    return _save(
      BackendConfig(
        baseUrl: uri.toString(),
        organisationId: organisationId.trim(),
      ),
      null,
    );
  }

  /// Signs in once, caches identity and roles durably, then reconciles attribution.
  Future<Result<void>> signIn(String email, String password) async {
    if (_offline()) return const FailureResult<void>(NetworkFailure());
    try {
      final TokenPair tokens = await BackendApiClient(send: _send).login(
        email: email.trim(),
        password: password,
        deviceId: deviceId,
        organisationId: _config.organisationId ?? '',
      );
      final BackendConfig identity = await _identity(tokens, email.trim());
      final Result<void> saved = await _save(identity, tokens);
      if (saved is FailureResult<void>) return saved;
      if (identity.accountId case final String id) await linkAccount?.call(id);
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        error is Failure
            ? error
            : const PermissionFailure(
                message: 'Sign-in was not accepted.',
                recoveryAction: 'Check your email, password and organisation.',
              ),
      );
    }
  }

  /// A bounded authenticated call. A 401 gets one silent rotation and retry.
  Future<({int status, Map<String, Object?> body})> send({
    required String method,
    required String path,
    Map<String, Object?>? body,
  }) async {
    if (!canUseBackend) return (status: 503, body: <String, Object?>{});
    try {
      var response = await _send(
        method: method,
        path: path,
        body: body,
        token: _tokens!.accessToken,
      );
      if (response.status == 401 && await refresh()) {
        response = await _send(
          method: method,
          path: path,
          body: body,
          token: _tokens!.accessToken,
        );
      }
      _reachability(true);
      return response;
    } on Object {
      _reachability(false);
      rethrow;
    }
  }

  /// Refreshes silently. Network failure preserves all local authority and input.
  Future<bool> refresh() async {
    if (_tokens == null || _offline()) return false;
    final Future<bool>? running = _refreshing;
    if (running != null) return running;
    final Future<bool> pending = _refresh();
    _refreshing = pending;
    try {
      return await pending;
    } finally {
      _refreshing = null;
    }
  }

  Future<bool> _refresh() async {
    try {
      final TokenPair tokens = await BackendApiClient(
        send: _send,
      ).refresh(refreshToken: _tokens!.refreshToken, reachable: true);
      // Rotation consumes the previous token. Persist its successor before any
      // subsequent network call so a dropped /me response cannot lose it.
      if (await _save(_config, tokens) is FailureResult<void>) return false;
      final BackendConfig identity = await _identity(
        tokens,
        _config.accountEmail ?? '',
      );
      return await _save(identity, tokens) is Success<void>;
    } on Object {
      _reachability(false);
      return false;
    }
  }

  /// Signs out explicitly. Local projects and operator attribution are untouched.
  Future<Result<void>> signOut() async {
    if (_tokens != null && !_offline()) {
      try {
        await _send(
          method: 'POST',
          path: '/api/v1/auth/logout',
          body: <String, Object?>{'refreshToken': _tokens!.refreshToken},
        );
      } on Object {
        /* Local sign-out remains available offline. */
      }
    }
    return _save(
      BackendConfig(
        baseUrl: _config.baseUrl,
        organisationId: _config.organisationId,
      ),
      null,
    );
  }

  Future<BackendConfig> _identity(TokenPair tokens, String email) async {
    final response = await _send(
      method: 'GET',
      path: '/api/v1/auth/me',
      token: tokens.accessToken,
    );
    final Map<String, Object?> body = response.body;
    final Object? id = body['userId'];
    final Object? org = body['organisationId'];
    final Object? role = body['role'];
    final Object? until = body['grantValidUntil'];
    if (response.status != 200 ||
        id is! String ||
        org is! String ||
        role is! String ||
        until is! String ||
        DateTime.tryParse(until) == null) {
      throw const FormatException();
    }
    final Map<String, String?> grants = <String, String?>{};
    if (body['grants'] case final List<Object?> rows) {
      for (final Object? row in rows) {
        if (row is Map<String, Object?> &&
            row['projectId'] is String &&
            (row['contextScope'] == null || row['contextScope'] is String)) {
          grants[row['projectId']! as String] = row['contextScope'] as String?;
        }
      }
    }
    return BackendConfig(
      baseUrl: _config.baseUrl,
      organisationId: org,
      accountEmail: email,
      accountId: id,
      role: role,
      aiAvailable: body['aiAvailable'] == true,
      grants: Map<String, String?>.unmodifiable(grants),
      grantValidUntil: DateTime.parse(until),
      state: EnrolmentState.enrolled,
    );
  }

  Future<Result<void>> _save(BackendConfig next, TokenPair? tokens) async {
    final Result<void> result = await _storage.putSecret(
      SecretKey.backendSession,
      jsonEncode(<String, Object?>{
        'baseUrl': next.baseUrl,
        'organisationId': next.organisationId,
        'accountEmail': next.accountEmail,
        'accountId': next.accountId,
        'role': next.role,
        'aiAvailable': next.aiAvailable,
        'grants': next.grants,
        'grantValidUntil': next.grantValidUntil?.toIso8601String(),
        'accessToken': tokens?.accessToken,
        'refreshToken': tokens?.refreshToken,
      }),
    );
    if (result is Success<void>) {
      _config = next;
      _tokens = tokens;
      _changes.add(next);
    }
    return result;
  }

  void _reachability(bool reachable) {
    if (_config.reachable == reachable) return;
    _config = BackendConfig(
      baseUrl: _config.baseUrl,
      organisationId: _config.organisationId,
      accountEmail: _config.accountEmail,
      accountId: _config.accountId,
      role: _config.role,
      aiAvailable: _config.aiAvailable,
      grants: _config.grants,
      state: _config.state,
      grantValidUntil: _config.grantValidUntil,
      reachable: reachable,
    );
    _changes.add(_config);
  }

  /// Closes the observer stream when its provider scope is disposed.
  Future<void> dispose() => _changes.close();
}

bool _online() => false;
