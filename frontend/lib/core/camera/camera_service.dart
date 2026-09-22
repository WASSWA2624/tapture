import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';

part 'camera_preview_state.dart';
part 'camera_flash_mode.dart';

/// Camera preview and shutter. Features never call a camera plugin
/// (FE-STR-11). Real builds may shutter through [PhotoPicker.take] with a
/// placeholder preview when no camera package is available.
abstract interface class CameraService {
  /// Platform-backed service that shutters via [picker].
  factory CameraService({PhotoPicker? picker}) {
    return _PhotoPickerCameraService(picker ?? PhotoPicker());
  }

  /// Stand-in that never opens a camera. Suites use this by default
  /// (FE-TEST-03).
  const factory CameraService.unavailable() = _UnavailableCameraService;

  /// Scripted stand-in for widget and unit tests.
  factory CameraService.fake({
    CameraPreviewState initial = CameraPreviewState.running,
    Uint8List? pictureBytes,
    Failure? takeFailure,
    Size previewSize = const Size(1280, 720),
    double minZoom = 1,
    double maxZoom = 8,
  }) {
    return _FakeCameraService(
      initial: initial,
      pictureBytes: pictureBytes ?? Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]),
      takeFailure: takeFailure,
      previewSize: previewSize,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// Live preview lifecycle.
  Stream<CameraPreviewState> get previewState;

  /// Reported preview size in pixels.
  Size get previewSize;

  /// Current flash mode.
  CameraFlashMode get flashMode;

  /// Whether the composition grid is on.
  bool get gridEnabled;

  /// Current zoom factor within [minZoom]–[maxZoom].
  double get zoom;

  /// Lower zoom bound.
  double get minZoom;

  /// Upper zoom bound.
  double get maxZoom;

  /// Starts the preview surface.
  Future<Result<void>> start();

  /// Stops and releases the preview surface.
  Future<Result<void>> stop();

  /// Pauses preview (app backgrounded).
  Future<Result<void>> pause();

  /// Rebuilds preview after [pause].
  Future<Result<void>> resume();

  /// Captures one frame as bytes. Preview stays live.
  Future<Result<Uint8List>> takePicture();

  /// Cycles flash off → auto → on.
  Future<CameraFlashMode> cycleFlash();

  /// Sets flash to [mode] and remembers it for the caller.
  Future<void> setFlash(CameraFlashMode mode);

  /// Tap-to-focus at normalised [x],[y] in 0–1.
  Future<void> focusAt(double x, double y);

  /// Clamps [factor] into [minZoom]–[maxZoom] and applies it.
  Future<double> setZoom(double factor);

  /// Turns the composition grid on or off.
  Future<void> setGridEnabled(bool enabled);
}

/// Process-wide camera. Default is unavailable until [main] overrides.
final Provider<CameraService> cameraServiceProvider = Provider<CameraService>((
  Ref _,
) {
  return const CameraService.unavailable();
});

final class _UnavailableCameraService implements CameraService {
  const _UnavailableCameraService();

  static const ProviderFailure _fail = ProviderFailure(
    message: Copy.photoNoCamera,
  );

  @override
  Stream<CameraPreviewState> get previewState =>
      Stream<CameraPreviewState>.value(CameraPreviewState.failed);

  @override
  Size get previewSize => Size.zero;

  @override
  CameraFlashMode get flashMode => CameraFlashMode.off;

  @override
  bool get gridEnabled => false;

  @override
  double get zoom => 1;

  @override
  double get minZoom => 1;

  @override
  double get maxZoom => 1;

  @override
  Future<Result<void>> start() async => const FailureResult<void>(_fail);

  @override
  Future<Result<void>> stop() async => const Success<void>(null);

  @override
  Future<Result<void>> pause() async => const Success<void>(null);

  @override
  Future<Result<void>> resume() async => const FailureResult<void>(_fail);

  @override
  Future<Result<Uint8List>> takePicture() async {
    return const FailureResult<Uint8List>(_fail);
  }

  @override
  Future<CameraFlashMode> cycleFlash() async => CameraFlashMode.off;

  @override
  Future<void> setFlash(CameraFlashMode mode) async {}

  @override
  Future<void> focusAt(double x, double y) async {}

  @override
  Future<double> setZoom(double factor) async => 1;

  @override
  Future<void> setGridEnabled(bool enabled) async {}
}

final class _FakeCameraService implements CameraService {
  _FakeCameraService({
    required CameraPreviewState initial,
    required this.pictureBytes,
    required this.takeFailure,
    required this.previewSize,
    required this.minZoom,
    required this.maxZoom,
  }) : _state = initial,
       _controller = StreamController<CameraPreviewState>.broadcast() {
    _controller.add(initial);
  }

  final Uint8List pictureBytes;
  final Failure? takeFailure;
  @override
  final Size previewSize;
  @override
  final double minZoom;
  @override
  final double maxZoom;

  CameraPreviewState _state;
  CameraFlashMode _flash = CameraFlashMode.off;
  bool _grid = false;
  double _zoom = 1;
  final StreamController<CameraPreviewState> _controller;

  @override
  Stream<CameraPreviewState> get previewState => _controller.stream;

  @override
  CameraFlashMode get flashMode => _flash;

  @override
  bool get gridEnabled => _grid;

  @override
  double get zoom => _zoom;

  void _emit(CameraPreviewState next) {
    _state = next;
    if (!_controller.isClosed) {
      _controller.add(next);
    }
  }

  @override
  Future<Result<void>> start() async {
    _emit(CameraPreviewState.starting);
    _emit(CameraPreviewState.running);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> stop() async {
    _emit(CameraPreviewState.failed);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> pause() async {
    if (_state == CameraPreviewState.running) {
      _emit(CameraPreviewState.starting);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> resume() async {
    _emit(CameraPreviewState.running);
    return const Success<void>(null);
  }

  @override
  Future<Result<Uint8List>> takePicture() async {
    final Failure? failure = takeFailure;
    if (failure != null) {
      return FailureResult<Uint8List>(failure);
    }
    return Success<Uint8List>(pictureBytes);
  }

  @override
  Future<CameraFlashMode> cycleFlash() async {
    _flash = switch (_flash) {
      CameraFlashMode.off => CameraFlashMode.auto,
      CameraFlashMode.auto => CameraFlashMode.on,
      CameraFlashMode.on => CameraFlashMode.off,
    };
    return _flash;
  }

  @override
  Future<void> setFlash(CameraFlashMode mode) async {
    _flash = mode;
  }

  @override
  Future<void> focusAt(double x, double y) async {}

  @override
  Future<double> setZoom(double factor) async {
    _zoom = factor.clamp(minZoom, maxZoom);
    return _zoom;
  }

  @override
  Future<void> setGridEnabled(bool enabled) async {
    _grid = enabled;
  }
}

final class _PhotoPickerCameraService implements CameraService {
  _PhotoPickerCameraService(this._picker);

  final PhotoPicker _picker;
  final StreamController<CameraPreviewState> _controller =
      StreamController<CameraPreviewState>.broadcast();
  CameraFlashMode _flash = CameraFlashMode.off;
  bool _grid = false;
  double _zoom = 1;
  CameraPreviewState _state = CameraPreviewState.failed;

  @override
  Stream<CameraPreviewState> get previewState => _controller.stream;

  @override
  Size get previewSize => const Size(1280, 720);

  @override
  CameraFlashMode get flashMode => _flash;

  @override
  bool get gridEnabled => _grid;

  @override
  double get zoom => _zoom;

  @override
  double get minZoom => 1;

  @override
  double get maxZoom => 4;

  void _emit(CameraPreviewState next) {
    _state = next;
    if (!_controller.isClosed) {
      _controller.add(next);
    }
  }

  @override
  Future<Result<void>> start() async {
    if (!_picker.canTakePhoto) {
      _emit(CameraPreviewState.failed);
      return const FailureResult<void>(
        ProviderFailure(message: Copy.photoNoCamera),
      );
    }
    _emit(CameraPreviewState.starting);
    _emit(CameraPreviewState.running);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> stop() async {
    _emit(CameraPreviewState.failed);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> pause() async {
    if (_state == CameraPreviewState.running) {
      _emit(CameraPreviewState.starting);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> resume() async {
    if (!_picker.canTakePhoto) {
      _emit(CameraPreviewState.failed);
      return const FailureResult<void>(
        ProviderFailure(message: Copy.photoNoCamera),
      );
    }
    _emit(CameraPreviewState.running);
    return const Success<void>(null);
  }

  @override
  Future<Result<Uint8List>> takePicture() async {
    final Result<List<Uint8List>> result = await _picker.take(longEdge: 2048);
    return result.fold(FailureResult<Uint8List>.new, (List<Uint8List> photos) {
      if (photos.isEmpty) {
        return const FailureResult<Uint8List>(
          CancelledFailure(message: Copy.photoPickFailed),
        );
      }
      return Success<Uint8List>(photos.first);
    });
  }

  @override
  Future<CameraFlashMode> cycleFlash() async {
    _flash = switch (_flash) {
      CameraFlashMode.off => CameraFlashMode.auto,
      CameraFlashMode.auto => CameraFlashMode.on,
      CameraFlashMode.on => CameraFlashMode.off,
    };
    return _flash;
  }

  @override
  Future<void> setFlash(CameraFlashMode mode) async {
    _flash = mode;
  }

  @override
  Future<void> focusAt(double x, double y) async {}

  @override
  Future<double> setZoom(double factor) async {
    _zoom = factor.clamp(minZoom, maxZoom);
    return _zoom;
  }

  @override
  Future<void> setGridEnabled(bool enabled) async {
    _grid = enabled;
  }
}
