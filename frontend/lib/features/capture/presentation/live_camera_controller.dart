import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Shutter and grid state for the live camera screen: each shot is written
/// before the next can be taken, and the preview redraws with the grid.
final class LiveCameraController extends Notifier<LiveCameraState> {
  /// Creates the controller for [camera] (family argument).
  LiveCameraController(this.camera);

  /// The camera this screen shoots with.
  final CameraService camera;

  @override
  LiveCameraState build() => (saving: false, grid: camera.gridEnabled);

  /// Takes one picture and waits for [write] to store it. A press while a
  /// shot is still being written does nothing.
  Future<Result<void>> shoot(
    Future<void> Function(Uint8List bytes) write,
  ) async {
    if (state.saving) {
      return const Success<void>(null);
    }
    state = (saving: true, grid: state.grid);
    try {
      final Result<Uint8List> shot = await camera.takePicture();
      switch (shot) {
        case Success<Uint8List>(:final Uint8List value):
          await write(value);
          return const Success<void>(null);
        case FailureResult<Uint8List>(:final Failure failure):
          return FailureResult<void>(failure);
      }
    } finally {
      if (ref.mounted) {
        state = (saving: false, grid: state.grid);
      }
    }
  }

  /// Keeps the grid the controls just set, so the preview draws it too.
  void setGrid(bool on) {
    state = (saving: state.saving, grid: on);
  }
}

/// Whether a shot is being written, and whether the grid is drawn.
typedef LiveCameraState = ({bool saving, bool grid});

/// One controller per open camera, released when its screen closes.
final liveCameraControllerProvider = NotifierProvider.autoDispose
    .family<LiveCameraController, LiveCameraState, CameraService>(
      LiveCameraController.new,
    );
