import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/camera/camera.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';

import 'live_camera_controller.dart';
import 'live_camera_state.dart';

/// Flash, grid, zoom and document-mode controls for the live camera: 48dp,
/// labelled, and naming their current state (FE-A11Y-01, FE-A11Y-02).
final class CameraControls extends ConsumerWidget {
  /// Creates controls wired to [camera].
  const CameraControls({required this.camera, super.key});

  /// How far one press of zoom in or zoom out moves.
  static const double zoomStep = 0.5;

  /// Camera port.
  final CameraService camera;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final LiveCameraState view = ref.watch(
      liveCameraControllerProvider(camera),
    );
    final LiveCameraController controller = ref.read(
      liveCameraControllerProvider(camera).notifier,
    );
    final (IconData flashIcon, String flashLabel) = switch (view.flash) {
      CameraFlashMode.off => (AppIcons.flashOff, localCopy.captureFlashOff),
      CameraFlashMode.auto => (AppIcons.flashAuto, localCopy.captureFlashAuto),
      CameraFlashMode.on => (AppIcons.flashOn, localCopy.captureFlashOn),
    };
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Space.x2,
      runSpacing: Space.x2,
      children: <Widget>[
        AppIconButton(
          icon: flashIcon,
          semanticLabel: flashLabel,
          tooltip: flashLabel,
          onPressed: () => unawaited(controller.cycleFlash()),
        ),
        AppIconButton(
          icon: view.grid ? AppIcons.gridOn : AppIcons.gridOff,
          semanticLabel: localCopy.captureGrid,
          tooltip: localCopy.captureGrid,
          selected: view.grid,
          onPressed: () => unawaited(controller.setGrid(!view.grid)),
        ),
        AppIconButton(
          icon: AppIcons.zoomOut,
          semanticLabel: localCopy.captureZoomOut,
          tooltip: localCopy.captureZoomOut,
          onPressed: view.zoom > camera.minZoom
              ? () => unawaited(controller.zoomBy(-zoomStep))
              : null,
        ),
        AppIconButton(
          icon: AppIcons.zoomIn,
          semanticLabel: localCopy.captureZoomIn,
          tooltip: localCopy.captureZoomIn,
          onPressed: view.zoom < camera.maxZoom
              ? () => unawaited(controller.zoomBy(zoomStep))
              : null,
        ),
        AppIconButton(
          icon: AppIcons.photoDocument,
          semanticLabel: localCopy.captureDocumentMode,
          tooltip: localCopy.captureDocumentMode,
          selected: view.documentMode,
          onPressed: () => controller.setDocumentMode(!view.documentMode),
        ),
      ],
    );
  }
}
