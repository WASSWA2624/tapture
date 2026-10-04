import 'package:flutter/foundation.dart';
import 'package:record/record.dart' as record;
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/permissions/permissions_service.dart';

/// Whether the app may open the microphone, asked the way each platform
/// answers truthfully.
///
/// Android, iOS and browsers go through [PermissionsService]. macOS asks
/// AVFoundation through the recorder, because the permission plugin has no
/// macOS answer. Windows reports a privacy block only when the stream
/// fails, and Linux has no microphone permission at all.
abstract interface class MicrophoneAccess {
  /// Access decided by [platform] (and [isWeb]), through [permissions] or
  /// [recorderPermission].
  factory MicrophoneAccess({
    required PermissionsService permissions,
    required Future<bool> Function({required bool request}) recorderPermission,
    required TargetPlatform platform,
    required bool isWeb,
  }) {
    return _MicrophoneAccess(
      permissions: permissions,
      recorderPermission: recorderPermission,
      platform: platform,
      isWeb: isWeb,
    );
  }

  /// Access on the running platform, asking the recorder plugin where the
  /// permission plugin cannot answer.
  factory MicrophoneAccess.platform({required PermissionsService permissions}) {
    return _MicrophoneAccess(
      permissions: permissions,
      recorderPermission: _recorderPermission,
      platform: defaultTargetPlatform,
      isWeb: kIsWeb,
    );
  }

  /// Asks for the microphone. Call only on an explicit tap: it may prompt,
  /// or open the settings page after a permanent refusal.
  Future<Result<void>> ensure();

  /// Whether the microphone is allowed now. Never prompts.
  Future<bool> isGranted();
}

/// The recorder plugin's own permission check, on a recorder opened for
/// the question and disposed after it.
Future<bool> _recorderPermission({required bool request}) async {
  final record.AudioRecorder recorder = record.AudioRecorder();
  try {
    return await recorder.hasPermission(request: request);
  } on Object {
    return false;
  } finally {
    await recorder.dispose();
  }
}

final class _MicrophoneAccess implements MicrophoneAccess {
  _MicrophoneAccess({
    required this._permissions,
    required this._recorderPermission,
    required this._platform,
    required this._isWeb,
  });

  final PermissionsService _permissions;
  final Future<bool> Function({required bool request}) _recorderPermission;
  final TargetPlatform _platform;
  final bool _isWeb;

  _Route get _route {
    if (_isWeb) {
      return _Route.permissions;
    }
    return switch (_platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => _Route.permissions,
      TargetPlatform.macOS || TargetPlatform.windows => _Route.recorder,
      TargetPlatform.linux => _Route.always,
    };
  }

  @override
  Future<Result<void>> ensure() async {
    switch (_route) {
      case _Route.always:
        return const Success<void>(null);
      case _Route.permissions:
        final Result<PermissionState> asked = await _permissions.request(
          AppPermission.microphone,
        );
        return asked.map((_) {});
      case _Route.recorder:
        if (await _recorderPermission(request: true)) {
          return const Success<void>(null);
        }
        return FailureResult<void>(_denied());
    }
  }

  @override
  Future<bool> isGranted() async {
    switch (_route) {
      case _Route.always:
        return true;
      case _Route.permissions:
        return await _permissions.status(AppPermission.microphone) ==
            PermissionState.granted;
      case _Route.recorder:
        return _recorderPermission(request: false);
    }
  }
}

/// Which source answers the permission question on this platform.
enum _Route { permissions, recorder, always }

PermissionFailure _denied() {
  return PermissionFailure(
    localizedMessage: Copy.messages.audioPermissionDenied,
    localizedRecovery: Copy.messages.audioPermissionRecovery,
  );
}
