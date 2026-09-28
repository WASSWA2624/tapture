part of 'camera_service.dart';

/// Makes the plugin controller for one camera.
typedef _Open =
    platform.CameraController Function(platform.CameraDescription camera);

/// The controller the live service opens for [camera]: stills only.
platform.CameraController _highResolutionController(
  platform.CameraDescription camera,
) {
  return platform.CameraController(
    camera,
    platform.ResolutionPreset.high,
    enableAudio: false,
  );
}

final class _DeviceCameraService
    implements CameraService, CameraPreviewSurface {
  _DeviceCameraService({
    required Future<List<platform.CameraDescription>> Function() listCameras,
    required _Open open,
  }) : _cameras = listCameras,
       _controllerFor = open;

  final Future<List<platform.CameraDescription>> Function() _cameras;
  final _Open _controllerFor;
  final StreamController<CameraPreviewState> _states =
      StreamController<CameraPreviewState>.broadcast();
  platform.CameraController? _camera;

  /// The open in flight and the [_generation] it was started for. A stop
  /// moves the generation on, so a later start never joins an open that the
  /// stop has already cancelled (the first-run permission prompt does this).
  Future<Result<void>>? _starting;
  int _startingGeneration = 0;
  CameraFlashMode _flash = CameraFlashMode.off;
  bool _grid = false;
  double _zoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
  int _generation = 0;

  @override
  Stream<CameraPreviewState> get previewState => _states.stream;
  @override
  Size get previewSize => _camera?.value.previewSize ?? Size.zero;
  @override
  CameraFlashMode get flashMode => _flash;
  @override
  bool get gridEnabled => _grid;
  @override
  double get zoom => _zoom;
  @override
  double get minZoom => _minZoom;
  @override
  double get maxZoom => _maxZoom;

  @override
  Widget buildPreview() {
    final platform.CameraController? camera = _camera;
    return camera != null && camera.value.isInitialized
        ? platform.CameraPreview(camera)
        : const SizedBox.shrink();
  }

  @override
  Future<Result<void>> start() {
    if (_camera?.value.isInitialized ?? false) {
      return Future<Result<void>>.value(const Success<void>(null));
    }
    final Future<Result<void>>? pending = _starting;
    if (pending != null && _startingGeneration == _generation) {
      return pending;
    }
    _startingGeneration = _generation;
    _states.add(CameraPreviewState.starting);
    final Future<Result<void>> opening = _openAfter(pending, _generation);
    _starting = opening;
    return opening;
  }

  /// Opens for [generation] once [previous], an open that a stop cancelled,
  /// has released the device, so the two never race for it.
  Future<Result<void>> _openAfter(
    Future<Result<void>>? previous,
    int generation,
  ) async {
    if (previous != null) {
      await previous;
    }
    final Result<void> opened = await _open(generation);
    if (_startingGeneration == generation) {
      _starting = null;
    }
    return opened;
  }

  /// Opens the back camera for [generation]. An open that a stop overtook
  /// releases what it opened and reports nothing: the view shows whatever
  /// the newer start reports.
  Future<Result<void>> _open(int generation) async {
    if (generation != _generation) {
      return const FailureResult<void>(CancelledFailure());
    }
    platform.CameraController? opened;
    try {
      final List<platform.CameraDescription> cameras = await _cameras();
      if (cameras.isEmpty) {
        throw const ProviderFailure(message: Copy.photoNoCamera);
      }
      final platform.CameraDescription back = cameras.firstWhere(
        (platform.CameraDescription item) =>
            item.lensDirection == platform.CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      opened = _controllerFor(back);
      await opened.initialize();
      if (generation != _generation) {
        await _release(opened);
        return const FailureResult<void>(CancelledFailure());
      }
      _minZoom = await opened.getMinZoomLevel();
      _maxZoom = await opened.getMaxZoomLevel();
      if (generation != _generation) {
        await _release(opened);
        return const FailureResult<void>(CancelledFailure());
      }
      _camera = opened;
      await setZoom(_zoom);
      await setFlash(_flash);
      if (generation != _generation) {
        // The stop that overtook this open has already released it.
        return const FailureResult<void>(CancelledFailure());
      }
      _states.add(CameraPreviewState.running);
      return const Success<void>(null);
    } on Object catch (error) {
      if (identical(_camera, opened)) {
        _camera = null;
      }
      await _release(opened);
      if (generation != _generation) {
        return const FailureResult<void>(CancelledFailure());
      }
      _states.add(CameraPreviewState.failed);
      return FailureResult<void>(_failure(error));
    }
  }

  /// Releases [camera] after a failed or overtaken open.
  Future<void> _release(platform.CameraController? camera) async {
    try {
      await camera?.dispose();
    } on Object {
      // A controller that never finished opening has nothing more to free.
    }
  }

  @override
  Future<Result<void>> stop() async {
    _generation++;
    final platform.CameraController? camera = _camera;
    _camera = null;
    if (camera != null) {
      // The view drops the released preview until the next start.
      _states.add(CameraPreviewState.starting);
    }
    try {
      await camera?.dispose();
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(_failure(error));
    }
  }

  @override
  Future<Result<void>> pause() => stop();
  @override
  Future<Result<void>> resume() => start();

  @override
  Future<Result<Uint8List>> takePicture() async {
    final platform.CameraController? camera = _camera;
    if (camera == null ||
        !camera.value.isInitialized ||
        camera.value.isTakingPicture) {
      return const FailureResult<Uint8List>(
        ProviderFailure(message: Copy.photoNoCamera),
      );
    }
    try {
      final platform.XFile picture = await camera.takePicture();
      return Success<Uint8List>(await picture.readAsBytes());
    } on Object catch (error) {
      return FailureResult<Uint8List>(_failure(error));
    }
  }

  @override
  Future<CameraFlashMode> cycleFlash() async {
    await setFlash(switch (_flash) {
      CameraFlashMode.off => CameraFlashMode.auto,
      CameraFlashMode.auto => CameraFlashMode.on,
      CameraFlashMode.on => CameraFlashMode.off,
    });
    return _flash;
  }

  @override
  Future<void> setFlash(CameraFlashMode mode) async {
    try {
      await _camera?.setFlashMode(switch (mode) {
        CameraFlashMode.off => platform.FlashMode.off,
        CameraFlashMode.auto => platform.FlashMode.auto,
        CameraFlashMode.on => platform.FlashMode.always,
      });
      _flash = mode;
    } on platform.CameraException {
      // Unsupported hardware leaves the last usable setting in force.
    }
  }

  @override
  Future<void> focusAt(double x, double y) async {
    try {
      await _camera?.setFocusPoint(Offset(x.clamp(0, 1), y.clamp(0, 1)));
    } on platform.CameraException {
      // Fixed-focus and web cameras keep their normal autofocus behaviour.
    }
  }

  @override
  Future<double> setZoom(double factor) async {
    final double next = factor.clamp(_minZoom, _maxZoom);
    try {
      await _camera?.setZoomLevel(next);
      _zoom = next;
    } on platform.CameraException {
      // Hardware without adjustable zoom stays at its last supported factor.
    }
    return _zoom;
  }

  @override
  Future<void> setGridEnabled(bool enabled) async => _grid = enabled;

  Failure _failure(Object error) {
    if (error is platform.CameraException && error.code.contains('Access')) {
      return const PermissionFailure(message: Copy.photoNoCamera);
    }
    return error is Failure
        ? error
        : const ProviderFailure(message: Copy.photoNoCamera);
  }
}
