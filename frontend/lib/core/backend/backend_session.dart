import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';

import 'backend_api_client.dart';
import 'backend_config.dart';
import 'backend_transport.dart';

/// Durable enrolment and rotating tokens, held only in platform secure storage.
///
/// The enrolment state moves only through [BackendConfig.apply]: sign-in
/// starts, then succeeds or fails; a refresh the server refuses with 401 or
/// 403 revokes. Nothing here waits on the network to answer what the device
/// may do: [config] and [authority] read the saved session and the clock.
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
       _usesPlatformSend = send == null,
       _config = BackendConfig(baseUrl: initialUrl) {
    _send = send ?? BackendTransport(baseUrl: () => _config.baseUrl).send;
  }

  final SecureStorage _storage;
  final Clock _clock;
  final bool Function() _offline;
  final bool _usesPlatformSend;
  late final BackendSend _send;
  final StreamController<BackendConfig> _changes =
      StreamController<BackendConfig>.broadcast();
  BackendConfig _config;
  TokenPair? _tokens;
  Future<bool>? _refreshing;

  /// When the server last confirmed the grant during this run.
  DateTime? _confirmedAt;

  /// Stable local device identifier; no provider key exists in this object.
  final String deviceId;

  /// Links the device profile to the account, preserving existing attribution.
  final Future<void> Function(String accountId)? linkAccount;

  /// The latest cached state, readable without waiting for any network call.
  BackendConfig get config => _config;

  /// Emits only after a durable local change or reachability change.
  Stream<BackendConfig> get changes => _changes.stream;

  /// How far the cached grant reaches now, from the saved session and the
  /// clock alone.
  AuthorityState get authority {
    if (_tokens == null) {
      // A revoked device keeps its identity; it has signed in before.
      return _config.state == EnrolmentState.revoked
          ? AuthorityState.cachedExpired
          : AuthorityState.neverSignedIn;
    }
    final DateTime now = _clock.nowUtc();
    final DateTime? until = _config.grantValidUntil;
    if (until == null || !until.isAfter(now)) {
      return AuthorityState.cachedExpired;
    }
    final DateTime? confirmed = _confirmedAt;
    if (confirmed != null &&
        now.difference(confirmed) <= AppConstants.backend.grantFreshFor) {
      return AuthorityState.fresh;
    }
    return AuthorityState.cachedValid;
  }

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
  bool get canUseBackend {
    if (_offline()) {
      return false;
    }
    final AuthorityState now = authority;
    return now == AuthorityState.fresh || now == AuthorityState.cachedValid;
  }

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
        state: _tokens != null
            ? EnrolmentState.enrolled
            : value['state'] == EnrolmentState.revoked.name
            ? EnrolmentState.revoked
            : EnrolmentState.notEnrolled,
      );
      if (_config.accountId case final String id when _tokens != null) {
        await linkAccount?.call(id);
      }
      return const Success<void>(null);
    } on Object {
      return FailureResult<void>(
        StorageFailure(
          localizedMessage: Copy.messages.failureTheSavedSignInCouldNotBe,
          localizedRecovery:
              Copy.messages.failureCheckTheAccountSettingsYourLocalWork,
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
      return FailureResult<void>(
        ValidationFailure(
          localizedMessage:
              Copy.messages.failureEnterTheOrganisationSHTTPSServerAddress,
          localizedRecovery:
              Copy.messages.failureCheckTheAddressWithYourAdministrator,
        ),
      );
    }
    if (_tokens != null &&
        (uri.toString() != _config.baseUrl ||
            organisationId.trim() != _config.organisationId)) {
      return FailureResult<void>(
        ValidationFailure(
          localizedMessage:
              Copy.messages.failureSignOutBeforeChangingOrganisation,
          localizedRecovery:
              Copy.messages.failureKeepTheCurrentAccountOrSignOut,
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

  /// Signs in once, caches identity and roles durably, then reconciles
  /// attribution. The state moves enrolling, then enrolled or back.
  Future<Result<void>> signIn(String email, String password) async {
    if (_offline()) return const FailureResult<void>(NetworkFailure());
    _publish(_config.apply(EnrolmentEvent.start));
    try {
      final TokenPair tokens = await BackendApiClient(send: _send).login(
        email: email.trim(),
        password: password,
        deviceId: deviceId,
        organisationId: _config.organisationId ?? '',
      );
      final BackendConfig identity = await _identity(tokens, email.trim());
      final Result<void> saved = await _save(
        identity.apply(EnrolmentEvent.succeed),
        tokens,
      );
      if (saved is FailureResult<void>) {
        _publish(_config.apply(EnrolmentEvent.fail));
        return saved;
      }
      _confirmedAt = _clock.nowUtc();
      if (identity.accountId case final String id) await linkAccount?.call(id);
      return const Success<void>(null);
    } on Object catch (error) {
      _publish(_config.apply(EnrolmentEvent.fail));
      return FailureResult<void>(
        error is Failure ? error : BackendApiClient.notAccepted,
      );
    }
  }

  /// A bounded authenticated call. A 401 gets one silent rotation and retry.
  Future<({int status, Map<String, Object?> body})> send({
    required String method,
    required String path,
    Map<String, Object?>? body,
    CancellationToken? cancellationToken,
  }) async {
    if (cancellationToken?.isCancelled == true) throw const CancelledFailure();
    if (!canUseBackend) return (status: 503, body: <String, Object?>{});
    Future<({int status, Map<String, Object?> body})> call() {
      final Future<({int status, Map<String, Object?> body})> pending =
          _usesPlatformSend
          ? BackendTransport(baseUrl: () => _config.baseUrl).send(
              method: method,
              path: path,
              body: body,
              token: _tokens!.accessToken,
              cancellationToken: cancellationToken,
            )
          : _send(
              method: method,
              path: path,
              body: body,
              token: _tokens!.accessToken,
            );
      return cancellationToken?.race(
            pending,
            onCancel: () => throw const CancelledFailure(),
          ) ??
          pending;
    }

    try {
      var response = await call();
      if (response.status == 401 && await refresh()) {
        if (cancellationToken?.isCancelled == true) {
          throw const CancelledFailure();
        }
        response = await call();
      }
      _reachability(true);
      return response;
    } on CancelledFailure {
      rethrow;
    } on Object {
      _reachability(false);
      rethrow;
    }
  }

  /// Refreshes silently. Network failure preserves all local authority and
  /// input; the server refusing the refresh token revokes the device.
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
    final TokenPair tokens;
    try {
      tokens = await BackendApiClient(
        send: _send,
      ).refresh(refreshToken: _tokens!.refreshToken);
    } on PermissionFailure {
      await _save(_config.apply(EnrolmentEvent.revoke), null);
      return false;
    } on Object {
      _reachability(false);
      return false;
    }
    try {
      // Rotation consumes the previous token. Persist its successor before any
      // subsequent network call so a dropped /me response cannot lose it.
      if (await _save(_config, tokens) is FailureResult<void>) return false;
      final BackendConfig identity = await _identity(
        tokens,
        _config.accountEmail ?? '',
      );
      final bool saved =
          await _save(identity.apply(EnrolmentEvent.succeed), tokens)
              is Success<void>;
      if (saved) {
        _confirmedAt = _clock.nowUtc();
      }
      return saved;
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
    _confirmedAt = null;
    return _save(
      BackendConfig(
        baseUrl: _config.baseUrl,
        organisationId: _config.organisationId,
      ),
      null,
    );
  }

  /// The identity `/auth/me` returns, still [EnrolmentState.enrolling].
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
      state: EnrolmentState.enrolling,
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
        'state': next.state.name,
        'accessToken': tokens?.accessToken,
        'refreshToken': tokens?.refreshToken,
      }),
    );
    if (result is Success<void>) {
      _tokens = tokens;
      _publish(next);
    }
    return result;
  }

  /// Makes [next] current and tells observers. Nothing is persisted here.
  void _publish(BackendConfig next) {
    _config = next;
    if (!_changes.isClosed) {
      _changes.add(next);
    }
  }

  void _reachability(bool reachable) {
    if (_config.reachable == reachable) return;
    _publish(
      BackendConfig(
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
      ),
    );
  }

  /// Closes the observer stream when its provider scope is disposed.
  Future<void> dispose() => _changes.close();
}

bool _online() => false;
