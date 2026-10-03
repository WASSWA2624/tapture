import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/camera/camera.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/feedback/haptics.dart';
import 'package:tapture/features/capture/domain/document_correction.dart';
import 'package:tapture/features/capture/domain/image_quality.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart';

import 'capture_controller.dart' show captureClockProvider, captureIdsProvider;
import 'live_camera_state.dart';

/// The live camera screen's state and intents: the preview lifecycle, a
/// shutter that writes each shot before it takes the next, the four
/// controls, and the advice on the last shot.
final class LiveCameraController extends Notifier<LiveCameraState> {
  /// Creates the controller for [camera] (family argument).
  LiveCameraController(this.camera);

  /// The camera this screen shoots with.
  final CameraService camera;

  StreamSubscription<CameraPreviewState>? _preview;

  SettingsStore get _settings => ref.read(projectSettingsStoreProvider);

  @override
  LiveCameraState build() {
    unawaited(_preview?.cancel());
    _preview = camera.previewState.listen(_onPreview);
    ref.onDispose(() {
      unawaited(_preview?.cancel());
      _preview = null;
      // Closing the screen, even while the camera is still opening,
      // releases it (FE-STATE-09).
      unawaited(camera.stop());
    });
    final SettingsStore settings = _settings;
    final CameraFlashMode flash = _flashNamed(settings.read(SettingKeys.flash));
    if (camera.flashMode != flash) {
      unawaited(_applyFlash(flash));
    }
    return LiveCameraState(
      grid: settings.read(SettingKeys.grid),
      flash: camera.flashMode,
      zoom: camera.zoom,
      // The camera default from Capture defaults (task 007) starts each
      // session; the toggle still changes it for this session only.
      documentMode:
          settings.read(SettingKeys.cameraMode) == _documentCameraMode,
    );
  }

  /// Opens the preview. A refused, restricted or missing camera ends in the
  /// failed state with its failure.
  Future<void> start() async => _opened(await camera.start());

  /// Releases the preview while the app is in the background.
  Future<void> pause() async {
    await camera.pause();
  }

  /// Rebuilds the preview after [pause].
  Future<void> resume() async => _opened(await camera.resume());

  /// Takes one picture and waits for [write] to store it durably before the
  /// shutter takes another (§22.1). A press while a shot is still being
  /// written does nothing. A failed shot or write hands its failure back.
  Future<Result<void>> shoot(
    Future<Result<PhotoDraft>> Function(Uint8List bytes) write,
  ) async {
    if (state.saving) {
      return const Success<void>(null);
    }
    state = state.copyWith(saving: true);
    try {
      final Result<Uint8List> shot = await camera.takePicture();
      switch (shot) {
        case FailureResult<Uint8List>(:final Failure failure):
          return FailureResult<void>(failure);
        case Success<Uint8List>(:final Uint8List value):
          final Result<PhotoDraft> written = await _write(write, value);
          switch (written) {
            case FailureResult<PhotoDraft>(:final Failure failure):
              return FailureResult<void>(failure);
            case Success<PhotoDraft>(value: final PhotoDraft photo):
              if (ref.mounted) {
                ref.read(hapticsProvider).shutter();
                unawaited(_review(photo, value));
              }
              return const Success<void>(null);
          }
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(saving: false);
      }
    }
  }

  /// Cycles flash off, auto, on and remembers the mode the camera applied.
  Future<void> cycleFlash() async {
    final CameraFlashMode mode = await camera.cycleFlash();
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(flash: mode);
    await _settings.write(SettingKeys.flash, mode.name);
  }

  /// Draws or hides the composition grid and remembers the choice.
  Future<void> setGrid(bool on) async {
    state = state.copyWith(grid: on);
    await _settings.write(SettingKeys.grid, on);
  }

  /// Zooms by [step], kept within the lens's reported range.
  Future<void> zoomBy(double step) => zoomTo(state.zoom + step);

  /// Zooms to [factor], kept within the lens's reported range.
  Future<void> zoomTo(double factor) async {
    final double applied = await camera.setZoom(factor);
    if (ref.mounted) {
      state = state.copyWith(zoom: applied);
    }
  }

  /// Focuses at [x], [y] across the preview, 0–1, and shows where.
  Future<void> focusAt(double x, double y) async {
    state = state.copyWith(focus: (x: x.clamp(0, 1), y: y.clamp(0, 1)));
    await camera.focusAt(x, y);
  }

  /// Turns document mode on or off for the next shots.
  void setDocumentMode(bool on) {
    state = state.copyWith(documentMode: on, clearDocument: !on);
  }

  /// Keeps the photo the quality advice was about. The default.
  void keepPhoto() {
    state = state.copyWith(clearQuality: true);
  }

  /// Sets the flagged photo aside through [discard] so the next shot takes
  /// its place. [discard] tombstones it: the file stays recoverable until
  /// the retention purge (FE-SEC-08).
  Future<Result<void>> retake(
    Future<Result<void>> Function(PhotoDraft photo) discard,
  ) async {
    final PhotoDraft? photo = state.quality?.photo;
    if (photo == null) {
      return const Success<void>(null);
    }
    final Result<void> discarded = await discard(photo);
    if (ref.mounted && discarded is Success<void>) {
      state = state.copyWith(clearQuality: true);
    }
    return discarded;
  }

  /// Keeps the uncorrected original only.
  void keepOriginal() {
    state = state.copyWith(clearDocument: true);
  }

  /// Stores the straightened copy through [store] as a derived file linked
  /// to the original, which stays unchanged beside it (FE-SEC-08).
  Future<void> useCorrected(
    Future<bool> Function(
      PhotoDraft original,
      PhotoDraft corrected,
      Uint8List bytes,
    )
    store,
  ) async {
    final ShotDocument? document = state.document;
    final Uint8List? bytes = document?.corrected;
    if (document == null || bytes == null) {
      return;
    }
    final bool stored = await store(
      document.photo,
      _derived(
        document.photo,
        id: ref.read(captureIdsProvider).newId(),
        at: ref.read(captureClockProvider).nowUtc(),
      ),
      bytes,
    );
    if (!ref.mounted) {
      return;
    }
    state = stored
        ? state.copyWith(clearDocument: true)
        : state.copyWith(
            document: (
              photo: document.photo,
              boundary: DocumentBoundary.correctionFailed,
              corrected: null,
            ),
          );
  }

  void _onPreview(CameraPreviewState next) {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      preview: next,
      clearFailure: next != CameraPreviewState.failed,
    );
  }

  void _opened(Result<void> opened) {
    if (!ref.mounted) {
      return;
    }
    if (opened case FailureResult<void>(:final Failure failure)) {
      // A start overtaken by a stop says nothing; the newer start reports.
      if (failure is! CancelledFailure) {
        state = state.copyWith(
          preview: CameraPreviewState.failed,
          failure: failure,
        );
      }
    }
  }

  Future<void> _applyFlash(CameraFlashMode mode) async {
    await camera.setFlash(mode);
    if (ref.mounted) {
      state = state.copyWith(flash: camera.flashMode);
    }
  }

  /// Scores the stored shot and, in document mode, looks for a page, off the
  /// UI thread. The shutter is already free again (§22.1, FE-PERF-02).
  Future<void> _review(PhotoDraft photo, Uint8List bytes) async {
    final bool document = state.documentMode;
    final ImageQualityFinding finding = await ImageQuality.scoreOffThread(
      bytes,
    );
    if (!ref.mounted) {
      return;
    }
    state = finding == ImageQualityFinding.clean
        ? state.copyWith(clearQuality: true)
        : state.copyWith(quality: (photo: photo, finding: finding));
    if (!document) {
      return;
    }
    final DocumentCorrectionResult corrected =
        await DocumentCorrection.correctOffThread(bytes);
    if (ref.mounted) {
      state = state.copyWith(
        document: (
          photo: photo,
          boundary: corrected.boundary,
          corrected: corrected.corrected,
        ),
      );
    }
  }
}

/// The stored camera default that opens capture in document mode.
const String _documentCameraMode = 'document';

/// One controller per open camera, released when its screen closes.
final liveCameraControllerProvider = NotifierProvider.autoDispose
    .family<LiveCameraController, LiveCameraState, CameraService>(
      LiveCameraController.new,
    );

/// [write], with anything it throws turned into its failure so the screen
/// can say what went wrong and stay open.
Future<Result<PhotoDraft>> _write(
  Future<Result<PhotoDraft>> Function(Uint8List bytes) write,
  Uint8List bytes,
) async {
  try {
    return await write(bytes);
  } on Object catch (error) {
    return FailureResult<PhotoDraft>(Failure.from(error));
  }
}

/// The derived-file record for a straightened copy of [original], stored in
/// the same folder and linked back to it.
PhotoDraft _derived(
  PhotoDraft original, {
  required String id,
  required DateTime at,
}) {
  final int slash = original.relativePath.lastIndexOf('/');
  final String folder = slash < 0
      ? ''
      : original.relativePath.substring(0, slash + 1);
  return original.copyWith(
    id: id,
    relativePath: '$folder$id.jpg',
    storedFilename: '$id.jpg',
    originalFilename: '$id.jpg',
    mimeType: 'image/jpeg',
    derivedFrom: original.id,
    rotationDegrees: 0,
    capturedAt: at,
  );
}

CameraFlashMode _flashNamed(String name) {
  for (final CameraFlashMode mode in CameraFlashMode.values) {
    if (mode.name == name) {
      return mode;
    }
  }
  return CameraFlashMode.off;
}
