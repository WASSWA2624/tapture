import 'package:permission_handler/permission_handler.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// The one caller of the runtime-permission plugin.
///
/// Tests pass [PermissionsService.fake] so they never touch the platform
/// (FE-STR-11, FE-TEST-03). GPS is off until [gpsEnabled] says otherwise
/// (FE-SEC-07).
abstract interface class PermissionsService {
  /// Asks the platform for camera, microphone, location or storage.
  ///
  /// [gpsEnabled] defaults to off. Location is not requested while it is off.
  factory PermissionsService({bool Function()? gpsEnabled}) {
    return _PermissionsService(
      read: _pluginRead,
      prompt: _pluginPrompt,
      openSettings: _pluginOpenSettings,
      gpsEnabled: gpsEnabled ?? _gpsOff,
    );
  }

  /// A hand-written stand-in driven by [states], so tests never open the plugin.
  factory PermissionsService.fake({
    Map<AppPermission, PermissionState>? states,
    bool Function()? gpsEnabled,
    void Function(AppPermission)? onPrompt,
    void Function(AppPermission)? onOpenSettings,
  }) {
    final Map<AppPermission, PermissionState> current =
        Map<AppPermission, PermissionState>.of(
          states ?? const <AppPermission, PermissionState>{},
        );
    return _PermissionsService(
      read: (AppPermission permission) async {
        return current[permission] ?? PermissionState.denied;
      },
      prompt: (AppPermission permission) async {
        onPrompt?.call(permission);
        return current[permission] ?? PermissionState.denied;
      },
      openSettings: (AppPermission permission) async {
        onOpenSettings?.call(permission);
      },
      gpsEnabled: gpsEnabled ?? _gpsOff,
    );
  }

  /// Asks for [permission] if it can still be prompted.
  ///
  /// A grant is [Success]. A denial is [PermissionFailure] with a recovery
  /// action. Permanent denial opens the settings page rather than repeating
  /// the prompt.
  Future<Result<PermissionState>> request(AppPermission permission);

  /// The current grant without prompting.
  Future<PermissionState> status(AppPermission permission);
}

/// The four runtime permissions this app asks for.
enum AppPermission {
  /// Photographs of equipment and documents.
  camera,

  /// Spoken notes on an explicit microphone tap.
  microphone,

  /// A capture stamp, only where a project has enabled GPS.
  location,

  /// Photos and files the operator chooses to import.
  storage,
}

/// What the platform currently allows.
enum PermissionState {
  /// The operator has granted the permission.
  granted,

  /// The operator refused, and the prompt may be shown again.
  denied,

  /// The operator refused, and only the settings page can change that.
  permanentlyDenied,
}

final class _PermissionsService implements PermissionsService {
  _PermissionsService({
    required this._read,
    required this._prompt,
    required this._openSettings,
    required this._gpsEnabled,
  });

  final _Read _read;
  final _Prompt _prompt;
  final _OpenSettings _openSettings;
  final bool Function() _gpsEnabled;

  @override
  Future<Result<PermissionState>> request(AppPermission permission) async {
    try {
      if (_locationBlocked(permission)) {
        return const FailureResult<PermissionState>(_locationOff);
      }
      final PermissionState current = await _read(permission);
      if (current == PermissionState.granted) {
        return const Success<PermissionState>(PermissionState.granted);
      }
      if (current == PermissionState.permanentlyDenied) {
        await _openSettings(permission);
        return FailureResult<PermissionState>(
          _failure(permission, permanent: true),
        );
      }
      final PermissionState next = await _prompt(permission);
      if (next == PermissionState.granted) {
        return const Success<PermissionState>(PermissionState.granted);
      }
      if (next == PermissionState.permanentlyDenied) {
        await _openSettings(permission);
        return FailureResult<PermissionState>(
          _failure(permission, permanent: true),
        );
      }
      return FailureResult<PermissionState>(
        _failure(permission, permanent: false),
      );
    } on Object catch (error) {
      return FailureResult<PermissionState>(Failure.from(error));
    }
  }

  @override
  Future<PermissionState> status(AppPermission permission) async {
    if (_locationBlocked(permission)) {
      return PermissionState.denied;
    }
    try {
      return await _read(permission);
    } on Object {
      return PermissionState.denied;
    }
  }

  bool _locationBlocked(AppPermission permission) {
    return permission == AppPermission.location && !_gpsEnabled();
  }
}

typedef _Read = Future<PermissionState> Function(AppPermission permission);
typedef _Prompt = Future<PermissionState> Function(AppPermission permission);
typedef _OpenSettings = Future<void> Function(AppPermission permission);

bool _gpsOff() => false;

const PermissionFailure _locationOff = PermissionFailure(
  message: 'Location is off for this project.',
  recoveryAction: 'Turn GPS on, then try again.',
);

PermissionFailure _failure(
  AppPermission permission, {
  required bool permanent,
}) {
  return PermissionFailure(
    message: _rationale(permission),
    recoveryAction: permanent
        ? 'Allow the permission in settings, then try again.'
        : 'Allow the permission, then try again.',
  );
}

String _rationale(AppPermission permission) {
  switch (permission) {
    case AppPermission.camera:
      return 'Tapture photographs equipment and documents.';
    case AppPermission.microphone:
      return 'Tapture records spoken notes when you tap the microphone.';
    case AppPermission.location:
      return 'Tapture can stamp a capture with this device\'s location.';
    case AppPermission.storage:
      return 'Tapture reads photos and files you choose to import.';
  }
}

Future<PermissionState> _pluginRead(AppPermission permission) async {
  return _map(await _plugin(permission).status);
}

Future<PermissionState> _pluginPrompt(AppPermission permission) async {
  return _map(await _plugin(permission).request());
}

Future<void> _pluginOpenSettings(AppPermission _) async {
  await openAppSettings();
}

Permission _plugin(AppPermission permission) {
  switch (permission) {
    case AppPermission.camera:
      return Permission.camera;
    case AppPermission.microphone:
      return Permission.microphone;
    case AppPermission.location:
      return Permission.locationWhenInUse;
    case AppPermission.storage:
      return Permission.photos;
  }
}

PermissionState _map(PermissionStatus status) {
  switch (status) {
    case PermissionStatus.granted:
    case PermissionStatus.limited:
    case PermissionStatus.provisional:
      return PermissionState.granted;
    case PermissionStatus.permanentlyDenied:
    case PermissionStatus.restricted:
      return PermissionState.permanentlyDenied;
    case PermissionStatus.denied:
      return PermissionState.denied;
  }
}
