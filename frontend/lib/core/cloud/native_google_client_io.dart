import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';

import 'cloud_destination.dart';
import 'cloud_settings.dart';
import 'google_drive_destination.dart';
import 'native_google_authorization.dart';

GoogleSignInAccount? _account;
Future<void>? _initialized;
const List<String> _scopes = <String>[GoogleDriveDestination.scope];

/// Android requires its registered web/server ID; iOS its own client ID.
bool get googleConfigured => Platform.isAndroid
    ? googleServerClientId.isNotEmpty
    : Platform.isIOS &&
          (cloudClientIds[DestinationKind.googleDrive] ?? '').isNotEmpty;

/// Obtains `drive.file` tokens from the maintained platform SDK only.
Future<GoogleAccess> requestGoogleAccess({
  required bool interactive,
  String? accountId,
  String? invalidToken,
}) async {
  if (!googleConfigured) throw _signInAgain;
  try {
    await (_initialized ??= _initialize());
    final GoogleSignIn signIn = GoogleSignIn.instance;
    GoogleSignInAccount? user = _account;
    if (interactive) {
      // The native SDK supports one current account. Saved destinations remain
      // bound to their own ID and refuse a silently substituted account.
      await signIn.signOut();
      user = await signIn.authenticate(scopeHint: _scopes);
      _account = user;
    } else if (user == null) {
      user = await signIn.attemptLightweightAuthentication();
      _account = user;
    }
    if (user == null || (!interactive && user.id != accountId)) {
      throw _signInAgain;
    }
    if (invalidToken != null) {
      await user.authorizationClient.clearAuthorizationToken(
        accessToken: invalidToken,
      );
    }
    GoogleSignInClientAuthorization? authorization = await user
        .authorizationClient
        .authorizationForScopes(_scopes);
    if (authorization == null && interactive) {
      authorization = await user.authorizationClient.authorizeScopes(_scopes);
    }
    if (authorization == null || authorization.accessToken.isEmpty) {
      throw _signInAgain;
    }
    return (accountId: user.id, token: authorization.accessToken);
  } on GoogleSignInException catch (error) {
    if (interactive && error.code == GoogleSignInExceptionCode.canceled) {
      throw const CancelledFailure();
    }
    throw _signInAgain;
  }
}

Future<void> _initialize() async {
  final GoogleSignIn signIn = GoogleSignIn.instance;
  await signIn.initialize(
    clientId: Platform.isIOS
        ? cloudClientIds[DestinationKind.googleDrive]
        : null,
    serverClientId: googleServerClientId.isEmpty ? null : googleServerClientId,
  );
  signIn.authenticationEvents.listen(
    (GoogleSignInAuthenticationEvent event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn(
          :final GoogleSignInAccount user,
        ):
          _account = user;
        case GoogleSignInAuthenticationEventSignOut():
          _account = null;
      }
    },
    onError: (Object _) {
      _account = null;
    },
  );
}

final PermissionFailure _signInAgain = PermissionFailure(
  localizedMessage: Copy.messages.failureGoogleDriveNeedsACurrentSignIn,
  localizedRecovery: Copy.messages.failureSignInAgainToAllowFileAccess,
);
