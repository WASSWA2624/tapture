import 'dart:typed_data';

import 'package:tapture/core/camera/camera.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/capture/domain/document_correction.dart';
import 'package:tapture/features/capture/domain/image_quality.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

/// What the live camera screen shows: the preview lifecycle, the shutter,
/// the four controls and the advice on the last shot.
final class LiveCameraState {
  /// Creates a state. Defaults describe a camera that is still opening.
  const LiveCameraState({
    this.preview = CameraPreviewState.starting,
    this.failure,
    this.saving = false,
    this.grid = false,
    this.flash = CameraFlashMode.off,
    this.zoom = 1,
    this.focus,
    this.documentMode = false,
    this.quality,
    this.document,
  });

  /// Starting, running or failed (FE-STATE-11).
  final CameraPreviewState preview;

  /// Why the preview failed, once the camera has said.
  final Failure? failure;

  /// Whether a shot is being written; the shutter waits for it.
  final bool saving;

  /// Whether the composition grid is drawn. Remembered between sessions.
  final bool grid;

  /// The flash mode the camera actually applied. Remembered between sessions.
  final CameraFlashMode flash;

  /// The zoom factor the camera actually applied.
  final double zoom;

  /// Where the last tap asked the lens to focus, 0–1 across the preview.
  final ({double x, double y})? focus;

  /// Whether each shot is also checked for a page to straighten.
  final bool documentMode;

  /// An advisory about the last shot; the photo is already stored.
  final ShotQuality? quality;

  /// Document mode's outcome for the last shot.
  final ShotDocument? document;

  /// A copy with the given fields replaced. The `clear…` flags drop a value.
  LiveCameraState copyWith({
    CameraPreviewState? preview,
    Failure? failure,
    bool clearFailure = false,
    bool? saving,
    bool? grid,
    CameraFlashMode? flash,
    double? zoom,
    ({double x, double y})? focus,
    bool? documentMode,
    ShotQuality? quality,
    bool clearQuality = false,
    ShotDocument? document,
    bool clearDocument = false,
  }) {
    return LiveCameraState(
      preview: preview ?? this.preview,
      failure: clearFailure ? null : failure ?? this.failure,
      saving: saving ?? this.saving,
      grid: grid ?? this.grid,
      flash: flash ?? this.flash,
      zoom: zoom ?? this.zoom,
      focus: focus ?? this.focus,
      documentMode: documentMode ?? this.documentMode,
      quality: clearQuality ? null : quality ?? this.quality,
      document: clearDocument ? null : document ?? this.document,
    );
  }
}

/// A quality finding about a stored [photo]. Advisory: the photo stays.
typedef ShotQuality = ({PhotoDraft photo, ImageQualityFinding finding});

/// Document mode's outcome for a stored [photo], with the straightened copy
/// when a page was found.
typedef ShotDocument = ({
  PhotoDraft photo,
  DocumentBoundary boundary,
  Uint8List? corrected,
});
