import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'cloud_oauth_redirect.dart';
import 'cloud_request_scope.dart';

/// Authorisation-code with PKCE, shared by Drive, OneDrive and Dropbox.
///
/// Each provider supplies endpoints and a scope. Access and refresh tokens
/// are read from secure storage on every call and never logged. A 401 refreshes
/// once; a failed refresh asks the person to sign in again and leaves the
/// destination in place.
final class OauthDestinationClient {
  /// Creates the client. [scheme] is the platform redirect scheme.
  OauthDestinationClient({
    required this.send,
    required this.readAccess,
    required this.writeAccess,
    required this.readRefresh,
    required this.writeRefresh,
    required this.scheme,
    required this.clientId,
    this._redirect,
    this.refreshAccess,
    this.uploadFingerprint,
    this._readUploadSession,
    this._writeUploadSession,
    this._writeRefreshedAccess,
    this._writeRefreshedRefresh,
    Random? random,
  }) : randomBytes = random ?? Random.secure();

  final Uri? _redirect;

  /// Source identity, computed on the upload worker.
  final String? uploadFingerprint;
  final Future<String?> Function()? _readUploadSession;
  final Future<void> Function(String? json)? _writeUploadSession;
  final Future<void> Function(String ref, String token)? _writeRefreshedAccess;
  final Future<void> Function(String ref, String token)? _writeRefreshedRefresh;

  /// Reads the provider checkpoint from secure storage.
  Future<String?> readUploadSession() async => _readUploadSession?.call();

  /// Saves a checkpoint; completion acknowledges durable secure persistence.
  Future<void> writeUploadSession(String? json) async {
    await _writeUploadSession?.call(json);
  }

  /// Transport for the token endpoint and authorised calls.
  final CloudSend send;

  /// Reads the access token for one destination.
  final SecretRead readAccess;

  /// Stores a new access token.
  final Future<void> Function(String ref, String token) writeAccess;

  /// Reads the refresh token for one destination.
  final SecretRead readRefresh;

  /// Stores a new refresh token.
  final Future<void> Function(String ref, String token) writeRefresh;

  /// Platform redirect scheme. Not a fixed string in this client.
  final String scheme;

  /// OAuth client id supplied by the caller.
  final String clientId;

  /// Native SDK renewal, when the provider does not expose refresh tokens.
  final Future<Result<String>> Function(String ref, String invalidToken)?
  refreshAccess;

  /// Random source for the PKCE verifier.
  final Random randomBytes;

  /// The redirect this client will send. Built from the platform [scheme].
  Uri get redirectUri => _redirect ?? Uri.parse('$scheme://oauth');

  /// Starts the code flow. The verifier must be kept until [exchange].
  ({Uri url, String verifier}) start(OauthProvider provider, String state) {
    final List<int> bytes = List<int>.generate(
      32,
      (_) => randomBytes.nextInt(256),
    );
    final String verifier = base64Url.encode(bytes).replaceAll('=', '');
    final String challenge = base64Url
        .encode(sha256.convert(utf8.encode(verifier)).bytes)
        .replaceAll('=', '');
    final Uri url = provider.authorize.replace(
      queryParameters: <String, String>{
        ...provider.authorizationParameters,
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri.toString(),
        'scope': provider.scope,
        'state': state,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    );
    return (url: url, verifier: verifier);
  }

  /// Trades [code] for tokens and stores them under [credentialRef].
  Future<Result<void>> exchange({
    required OauthProvider provider,
    required String credentialRef,
    required String code,
    required String verifier,
    Uri? redirect,
  }) async {
    return Result.captureAsync<void>(() async {
      final Uri actual = redirect ?? redirectUri;
      if (!CloudOauthRedirect.matches(redirectUri, actual)) {
        throw _reauth;
      }
      _checkCancelled();
      final CloudReply reply = await _token(provider, <String, String>{
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': verifier,
        'redirect_uri': actual.toString(),
        'client_id': clientId,
      });
      _checkCancelled();
      (await _store(credentialRef, reply)).getOrThrow();
    });
  }

  /// Sends [call] with the stored access token. On 401, refreshes once.
  Future<Result<CloudReply>> sendAuthorized({
    required OauthProvider provider,
    required String credentialRef,
    required CloudCall call,
    CancellationToken? cancel,
  }) async {
    return CloudRequestScope(
      cancel: cancel ?? CloudRequestScope.current.cancel,
    ).run(
      () => Result.captureAsync<CloudReply>(() async {
        final String? access = await readAccess(credentialRef);
        if (access == null || access.isEmpty) {
          throw _reauth;
        }
        final CloudReply first = await send(_withBearer(call, access));
        if (first.status != 401) {
          return first;
        }
        final Result<String> refreshed = await _refresh(
          provider,
          credentialRef,
          access,
        );
        if (refreshed is FailureResult<String>) {
          throw refreshed.failure;
        }
        final CloudReply second = await send(
          _withBearer(call, (refreshed as Success<String>).value),
        );
        if (second.status == 401 || second.status == 403) {
          throw _reauth;
        }
        return second;
      }),
    );
  }

  /// Sends to a signed upload URL without disclosing the OAuth bearer.
  Future<Result<CloudReply>> sendPublic({
    required CloudCall call,
    CancellationToken? cancel,
  }) => CloudRequestScope(
    cancel: cancel ?? CloudRequestScope.current.cancel,
  ).run(() => Result.captureAsync<CloudReply>(() => send(call)));

  Future<Result<String>> _refresh(
    OauthProvider provider,
    String credentialRef,
    String invalidToken,
  ) async {
    if (refreshAccess != null) {
      return refreshAccess!(credentialRef, invalidToken);
    }
    final String? refresh = await readRefresh(credentialRef);
    if (refresh == null || refresh.isEmpty) {
      return FailureResult<String>(_reauth);
    }
    final CloudReply reply = await _token(provider, <String, String>{
      'grant_type': 'refresh_token',
      'refresh_token': refresh,
      'client_id': clientId,
    });
    final Result<void> stored = await _store(
      credentialRef,
      reply,
      refreshing: true,
    );
    if (stored is FailureResult<void>) {
      return FailureResult<String>(stored.failure);
    }
    final String? access = await readAccess(credentialRef);
    if (access == null || access.isEmpty) {
      return FailureResult<String>(_reauth);
    }
    return Success<String>(access);
  }

  Future<CloudReply> _token(
    OauthProvider provider,
    Map<String, String> fields,
  ) {
    return send((
      method: 'POST',
      url: provider.token,
      headers: <String, String>{
        'content-type': 'application/x-www-form-urlencoded',
      },
      body: utf8.encode(Uri(queryParameters: fields).query),
    ));
  }

  Future<Result<void>> _store(
    String credentialRef,
    CloudReply reply, {
    bool refreshing = false,
  }) async {
    if (reply.status < 200 || reply.status >= 300) {
      return FailureResult<void>(_reauth);
    }
    try {
      final Object? decoded = jsonDecode(utf8.decode(reply.body));
      if (decoded is! Map) {
        return FailureResult<void>(_reauth);
      }
      final String access = '${decoded['access_token'] ?? ''}';
      if (access.isEmpty) {
        return FailureResult<void>(_reauth);
      }
      _checkCancelled();
      await (refreshing ? _writeRefreshedAccess ?? writeAccess : writeAccess)(
        credentialRef,
        access,
      );
      _checkCancelled();
      final String refresh = '${decoded['refresh_token'] ?? ''}';
      if (refresh.isNotEmpty) {
        await (refreshing
            ? _writeRefreshedRefresh ?? writeRefresh
            : writeRefresh)(credentialRef, refresh);
      }
      _checkCancelled();
      return const Success<void>(null);
    } on FormatException {
      return FailureResult<void>(_reauth);
    }
  }

  void _checkCancelled() {
    if (CloudRequestScope.current.cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
  }

  CloudCall _withBearer(CloudCall call, String access) {
    return (
      method: call.method,
      url: call.url,
      headers: <String, String>{
        ...call.headers,
        'authorization': 'Bearer $access',
      },
      body: call.body,
    );
  }
}

/// Endpoints and the one scope a provider asks for.
typedef OauthProvider = ({
  String name,
  Uri authorize,
  Uri token,
  String scope,
  Map<String, String> authorizationParameters,
});

final PermissionFailure _reauth = PermissionFailure(
  localizedMessage: Copy.messages.failureSignInToThisDestinationAgain,
  localizedRecovery: Copy.messages.failureTheDestinationIsStillSavedSignIn,
);
