import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:local_auth_darwin/types/auth_messages_macos.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'biometric_prompt.dart';

/// Biometric authentication at the platform boundary. Unsupported hosts and
/// every cancellation or device failure leave the app's PIN gate armed.
final class BiometricService {
  /// Uses the maintained native SDK. [authentication] and [supported] allow
  /// tests to exercise SDK options without a real enrolled device.
  BiometricService({
    LocalAuthentication? authentication,
    bool? supported,
    Duration? timeout,
  }) : _authentication = authentication ?? LocalAuthentication(),
       _supported =
           supported ??
           (!kIsWeb &&
               const <TargetPlatform>{
                 TargetPlatform.android,
                 TargetPlatform.iOS,
                 TargetPlatform.macOS,
               }.contains(defaultTargetPlatform)),
       _timeout = timeout ?? AppConstants.lock.biometricTimeout;

  final LocalAuthentication _authentication;
  final bool _supported;
  final Duration _timeout;
  bool _active = false;

  /// Checks hardware support without starting authentication or a permission
  /// prompt. Enrollment and Face ID authorization are handled only after the
  /// operator presses the biometric action.
  Future<bool> isAvailable() async {
    if (!_supported) {
      return false;
    }
    try {
      return await _authentication.canCheckBiometrics.timeout(
        AppConstants.lock.storageTimeout,
      );
    } on Object {
      return false;
    }
  }

  /// Opens one user-requested biometric challenge with localized UI copy.
  /// Device passcodes never replace the app's own PIN. Backgrounding cancels
  /// the challenge; a timed-out native call is stopped and cannot unlock late.
  Future<Result<bool>> authenticate({
    required String localizedReason,
    BiometricPrompt? prompt,
  }) async {
    if (_active || localizedReason.trim().isEmpty) {
      return FailureResult<bool>(_unavailable);
    }
    _active = true;
    try {
      if (!await isAvailable()) {
        return FailureResult<bool>(_unavailable);
      }
      return Success<bool>(
        await _authentication
            .authenticate(
              localizedReason: localizedReason,
              authMessages: _messages(prompt),
              biometricOnly: true,
              sensitiveTransaction: true,
              persistAcrossBackgrounding: false,
            )
            .timeout(_timeout),
      );
    } on TimeoutException {
      try {
        await _authentication.stopAuthentication().timeout(
          AppConstants.lock.storageTimeout,
        );
      } on Object {
        // The timeout result already keeps the app locked.
      }
      return const FailureResult<bool>(CancelledFailure());
    } on LocalAuthException catch (error) {
      return FailureResult<bool>(switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback =>
          const CancelledFailure(),
        _ => _unavailable,
      });
    } on Object {
      return FailureResult<bool>(_unavailable);
    } finally {
      _active = false;
    }
  }

  Iterable<AuthMessages> _messages(BiometricPrompt? supplied) {
    final BiometricPrompt prompt =
        supplied ??
        BiometricPrompt(
          title: Copy.appLockUnlockTitle,
          hint: Copy.appLockBiometrics,
          cancel: Copy.cancel,
        );
    return <AuthMessages>[
      AndroidAuthMessages(
        signInTitle: prompt.title,
        signInHint: prompt.hint,
        cancelButton: prompt.cancel,
      ),
      IOSAuthMessages(cancelButton: prompt.cancel, localizedFallbackTitle: ''),
      MacOSAuthMessages(
        cancelButton: prompt.cancel,
        localizedFallbackTitle: '',
      ),
    ];
  }
}

final PermissionFailure _unavailable = PermissionFailure(
  localizedMessage: Copy.messages.failureBiometricAuthenticationIsUnavailable,
  localizedRecovery: Copy.messages.failureUnlockWithYourAppPIN,
);
