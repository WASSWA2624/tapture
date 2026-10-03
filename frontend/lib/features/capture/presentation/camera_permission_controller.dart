import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/permissions/permissions_service.dart';

/// Whether the live camera may open, asked at first need and never at
/// launch (step 3).
///
/// The reason is shown before the system prompt. Once it has been read, the
/// camera opens and the camera plug-in asks the system itself, so there is
/// exactly one prompt on every platform; a refusal there ends in the
/// preview's failed state. A permanent refusal offers the settings page.
final class CameraPermissionController extends AsyncNotifier<CameraAccess> {
  @override
  Future<CameraAccess> build() async {
    // Coming back from the settings page reads the grant again, so a camera
    // allowed there opens without another tap.
    final AppLifecycleListener returned = AppLifecycleListener(
      onResume: () {
        if (ref.mounted && state.value == CameraAccess.settings) {
          ref.invalidateSelf();
        }
      },
    );
    ref.onDispose(returned.dispose);
    final PermissionState grant = await ref
        .watch(permissionsServiceProvider)
        .status(AppPermission.camera);
    return switch (grant) {
      PermissionState.granted => CameraAccess.open,
      PermissionState.denied => CameraAccess.explain,
      PermissionState.permanentlyDenied => CameraAccess.settings,
    };
  }

  /// The reason has been read: open the camera, which asks the system.
  void allow() {
    state = const AsyncData<CameraAccess>(CameraAccess.open);
  }

  /// Opens the system settings page, the only way back from a permanent
  /// refusal, then reads the grant again.
  Future<void> openSettings() async {
    await ref.read(permissionsServiceProvider).request(AppPermission.camera);
    if (ref.mounted) {
      ref.invalidateSelf();
    }
  }
}

/// What the camera gate shows.
enum CameraAccess {
  /// The reason, with a control that opens the camera.
  explain,

  /// The reason, with a route to the system settings page.
  settings,

  /// The live camera.
  open,
}

/// The camera gate's state, re-read each time the camera is opened.
final cameraPermissionProvider =
    AsyncNotifierProvider.autoDispose<CameraPermissionController, CameraAccess>(
      CameraPermissionController.new,
    );
