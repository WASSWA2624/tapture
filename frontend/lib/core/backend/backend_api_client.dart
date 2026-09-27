import 'dart:async';

/// Authentication calls. The only HTTP the enrolment flow uses.
final class BackendApiClient {
  /// Creates a client. [send] performs the request.
  const BackendApiClient({required this.send});

  /// Transport. Tests substitute a fake.
  final BackendSend send;

  /// Signs in. The body is the token pair.
  Future<TokenPair> login({
    required String email,
    required String password,
    required String deviceId,
    required String organisationId,
  }) async {
    final ({int status, Map<String, Object?> body}) response = await send(
      method: 'POST',
      path: '/api/v1/auth/login',
      body: <String, Object?>{
        'email': email,
        'password': password,
        'deviceId': deviceId,
        'organisationId': organisationId,
      },
    );
    return _pair(response);
  }

  /// Rotates a refresh token when the server can be reached.
  ///
  /// Offline, the cached access token is returned and nothing is sent.
  Future<TokenPair> refresh({
    required String refreshToken,
    required bool reachable,
    String? cachedAccess,
  }) async {
    if (!reachable) {
      return (accessToken: cachedAccess ?? '', refreshToken: refreshToken);
    }
    final ({int status, Map<String, Object?> body}) response = await send(
      method: 'POST',
      path: '/api/v1/auth/refresh',
      body: <String, Object?>{'refreshToken': refreshToken},
    );
    return _pair(response);
  }

  TokenPair _pair(({int status, Map<String, Object?> body}) response) {
    if (response.status != 200) {
      throw StateError('Sign-in was not accepted.');
    }
    final Object? access = response.body['accessToken'];
    final Object? refresh = response.body['refreshToken'];
    if (access is! String || refresh is! String) {
      throw StateError('Sign-in was not accepted.');
    }
    return (accessToken: access, refreshToken: refresh);
  }
}

/// One HTTP call. Screens never construct this themselves.
typedef BackendSend =
    Future<({int status, Map<String, Object?> body})> Function({
      required String method,
      required String path,
      Map<String, Object?>? body,
      String? token,
    });

/// Tokens from one sign-in. They leave this type only for secure storage.
typedef TokenPair = ({String accessToken, String refreshToken});
