import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import 'camera_controls.dart';
import 'camera_view.dart';
import 'live_camera_controller.dart';

/// Repeated shutter captures are persisted by the caller before the next shot.
class LiveCameraScreen extends ConsumerWidget {
  /// Shoots with [camera]; [onCaptured] writes each shot durably.
  const LiveCameraScreen({
    required this.camera,
    required this.onCaptured,
    super.key,
  });

  /// Live camera adapter.
  final CameraService camera;

  /// Finishes the evidence write before returning.
  final Future<void> Function(Uint8List bytes) onCaptured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LiveCameraState view = ref.watch(
      liveCameraControllerProvider(camera),
    );
    final LiveCameraController controller = ref.read(
      liveCameraControllerProvider(camera).notifier,
    );
    return Scaffold(
      appBar: AppBar(title: const Text(Copy.captureTitle)),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Center(
              child: CameraView(camera: camera, gridOverlay: view.grid),
            ),
            CameraControls(
              camera: camera,
              onShutter: view.saving
                  ? null
                  : () => unawaited(_shoot(context, controller)),
              onGridChanged: controller.setGrid,
            ),
            if (view.saving)
              const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _shoot(
    BuildContext context,
    LiveCameraController controller,
  ) async {
    final Result<void> shot = await controller.shoot(onCaptured);
    if (!context.mounted) {
      return;
    }
    if (shot case FailureResult<void>(:final Failure failure)) {
      showAppSnack(context, failure.message, tone: SnackTone.error);
    }
  }
}
