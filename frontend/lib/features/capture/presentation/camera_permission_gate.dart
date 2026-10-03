import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/permissions/permission_rationale.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import 'camera_permission_controller.dart';

/// Shows why the camera is needed before the system asks, and [child] once
/// the camera may open. A permanent refusal offers the settings page;
/// gallery import and typed capture stay one step back (STANDARD rule 3).
final class CameraPermissionGate extends ConsumerWidget {
  /// Creates a gate around [child].
  const CameraPermissionGate({required this.child, super.key});

  /// The live camera, built only once it may open.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CameraPermissionController controller = ref.read(
      cameraPermissionProvider.notifier,
    );
    return AsyncValueView<CameraAccess>(
      value: ref.watch(cameraPermissionProvider),
      loadingShape: SkeletonShape.card,
      loadingCount: 1,
      onRetry: () => ref.invalidate(cameraPermissionProvider),
      data: (CameraAccess access) {
        final LocalizedCopy localCopy = Copy.of(context);

        if (access == CameraAccess.open) {
          return child;
        }
        final bool settings = access == CameraAccess.settings;
        return Center(
          child: SingleChildScrollView(
            child: AppEmptyState(
              icon: AppIcons.camera,
              headline: localCopy.captureCameraTitle,
              message: PermissionRationale.of(AppPermission.camera).message,
              actionLabel: settings
                  ? localCopy.captureOpenCameraSettings
                  : localCopy.captureAllowCamera,
              onAction: settings
                  ? () => unawaited(controller.openSettings())
                  : controller.allow,
            ),
          ),
        );
      },
    );
  }
}
