import 'dart:async';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';

/// Authentication calls. The only HTTP the enrolment flow uses.
final class BackendApiClient {
  /// Creates a client. [send] performs the request.
  const BackendApiClient({required this.send});

  /// Transport. Tests substitute a fake.
  final BackendSend send;

  /// Signs in. The body is the token pair. The server refusing the
  /// credentials is a [PermissionFailure]; a server that cannot answer is a
  /// [NetworkFailure].
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
        if (organisationId.isNotEmpty) 'organisationId': organisationId,
      },
    );
    if (response.status >= 400 && response.status < 500) {
      throw notAccepted;
    }
    return _pair(response);
  }

  /// Rotates a refresh token. A 401 or 403 means the organisation ended
  /// this device's sign-in ([revoked]); any other refusal is the server
  /// being unavailable, which changes nothing on the device.
  Future<TokenPair> refresh({required String refreshToken}) async {
    final ({int status, Map<String, Object?> body}) response = await send(
      method: 'POST',
      path: '/api/v1/auth/refresh',
      body: <String, Object?>{'refreshToken': refreshToken},
    );
    if (response.status == 401 || response.status == 403) {
      throw revoked;
    }
    return _pair(response);
  }

  /// The server refused the email, password or organisation.
  static final PermissionFailure notAccepted = PermissionFailure(
    localizedMessage: Copy.messages.failureSignInWasNotAccepted,
    localizedRecovery:
        Copy.messages.failureCheckYourEmailPasswordAndOrganisation,
  );

  /// The organisation ended this device's sign-in.
  static final PermissionFailure revoked = PermissionFailure(
    localizedMessage: Copy.messages.failureTheOrganisationEndedThisDeviceSSign,
    localizedRecovery: Copy.messages.failureSignInAgainWhenTheServerIs,
  );

  TokenPair _pair(({int status, Map<String, Object?> body}) response) {
    final Object? access = response.body['accessToken'];
    final Object? refresh = response.body['refreshToken'];
    if (response.status != 200 || access is! String || refresh is! String) {
      throw NetworkFailure(
        localizedMessage: Copy.messages.failureTheServerCouldNotCompleteSignIn,
        localizedRecovery:
            Copy.messages.failureTryAgainWhenTheServerIsReachable,
      );
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
