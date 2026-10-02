import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_settings.dart';
import 'desktop_cloud_sign_in.dart';

const MethodChannel _channel = MethodChannel('com.tapture.app/cloud');
final DesktopCloudSignIn _desktop = DesktopCloudSignIn();

/// Mobile uses its native session; desktop uses a configured loopback receiver.
CloudSignIn? platformCloudSignIn() => Platform.isAndroid || Platform.isIOS
    ? signInCloud
    : Platform.isWindows || Platform.isMacOS || Platform.isLinux
    ? (Uri authorize, Uri redirect) => _desktop.signIn(authorize, redirect)
    : null;

/// Opens a native browser session and checks its exact registered callback.
/// A timeout cancels the native pending session; callback parameters are never logged.
Future<Result<Uri>> signInCloud(Uri authorize, Uri redirect) async {
  if (authorize.scheme != 'https' ||
      redirect.scheme != 'tapture' ||
      redirect.host != 'oauth' ||
      redirect.path.isNotEmpty) {
    return FailureResult<Uri>(_failed);
  }
  try {
    final String? returned = await _channel
        .invokeMethod<String>('signIn', <String, String>{
          'authorize': authorize.toString(),
          'redirect': redirect.toString(),
        })
        .timeout(AppConstants.cloudUpload.signInTimeout);
    final Uri? callback = Uri.tryParse(returned ?? '');
    if (callback == null ||
        callback.scheme != redirect.scheme ||
        callback.host != redirect.host ||
        callback.path != redirect.path ||
        callback.userInfo.isNotEmpty ||
        callback.hasPort) {
      return FailureResult<Uri>(_failed);
    }
    if (callback.queryParameters['error'] == 'access_denied') {
      return const FailureResult<Uri>(CancelledFailure());
    }
    return Success<Uri>(callback);
  } on PlatformException catch (error) {
    return error.code == 'cancelled'
        ? const FailureResult<Uri>(CancelledFailure())
        : FailureResult<Uri>(_failed);
  } on Object {
    try {
      await _channel.invokeMethod<void>('cancelSignIn');
    } on Object {
      /* The native receiver may already have closed. */
    }
    return FailureResult<Uri>(_failed);
  }
}

final PermissionFailure _failed = PermissionFailure(
  localizedMessage: Copy.messages.failureCloudSignInCouldNotFinish,
  localizedRecovery: Copy.messages.failureTrySigningInAgain,
);
