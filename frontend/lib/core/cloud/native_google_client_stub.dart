import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';

import 'native_google_authorization.dart';

/// A native Google SDK is unavailable on browser/desktop builds.
bool get googleConfigured => false;

/// Unsupported platforms never initiate an authentication flow.
Future<GoogleAccess> requestGoogleAccess({
  required bool interactive,
  String? accountId,
  String? invalidToken,
}) async => throw PermissionFailure(
  localizedMessage: Copy.messages.failureNativeGoogleDriveSignInIsUnavailable,
);
