part of 'camera_service.dart';

/// Preview lifecycle for capture UI (FE-STATE-11).
enum CameraPreviewState {
  /// Opening the surface.
  starting,

  /// Live preview.
  running,

  /// Missing, refused or unreadable.
  failed,
}
