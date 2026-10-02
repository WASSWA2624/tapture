part of 'barcode_scanner_service.dart';

/// The controller the device scanner opens: started on demand only.
platform.MobileScannerController _openController() {
  return platform.MobileScannerController(autoStart: false);
}

final class _DeviceBarcodeScanner
    implements BarcodeScannerService, CameraPreviewSurface {
  _DeviceBarcodeScanner({required this._open});

  final platform.MobileScannerController Function() _open;
  platform.MobileScannerController? _camera;
  StreamSubscription<platform.BarcodeCapture>? _subscription;
  final StreamController<BarcodeHit> _hits =
      StreamController<BarcodeHit>.broadcast();

  platform.MobileScannerController get _controller => _camera ??= _open();

  @override
  Stream<BarcodeHit> get hits => _hits.stream;

  /// Known only once the scanner has started; until then there is no torch.
  @override
  bool get torchSupported {
    final platform.TorchState? torch = _camera?.value.torchState;
    return torch != null && torch != platform.TorchState.unavailable;
  }

  @override
  bool get torchOn => _camera?.value.torchState == platform.TorchState.on;

  @override
  Widget buildPreview() => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints space) {
      // Only codes inside the region the screen draws are read.
      final double side =
          min(space.maxWidth, space.maxHeight) *
          BarcodeScannerService.scanRegionShare;
      return platform.MobileScanner(
        controller: _controller,
        tapToFocus: true,
        scanWindow: Rect.fromCenter(
          center: space.biggest.center(Offset.zero),
          width: side,
          height: side,
        ),
        errorBuilder: (_, _) =>
            Center(child: Text(Copy.of(context).barcodeUnavailable)),
      );
    },
  );

  @override
  Future<Result<void>> start() async {
    try {
      if (kIsWeb) {
        // A browser without a native detector decodes with the same-origin
        // script, never one fetched from a CDN (§7.1).
        platform.MobileScannerPlatform.instance
          ..setWebBarcodeReader(
            web.hasNativeBarcodeDetector()
                ? platform.WebBarcodeReader.barcodeDetector
                : platform.WebBarcodeReader.zxingJs,
          )
          ..setBarcodeLibraryScriptUrl(BarcodeScannerService.webDecoderScript);
      }
      _subscription ??= _controller.barcodes.listen(
        _decoded,
        onError: (Object _, StackTrace _) {
          // An unreadable frame leaves scanning active; the user can type
          // instead or try again.
          if (!_hits.isClosed) {
            _hits.addError(
              ProviderFailure(
                localizedMessage: Copy.messages.barcodeUnreadable,
              ),
            );
          }
        },
      );
      final platform.MobileScannerController camera = _controller;
      await camera.start();
      // The controller keeps a refused or failed start in its value rather
      // than throwing it.
      final platform.MobileScannerException? refused = camera.value.error;
      return refused == null
          ? const Success<void>(null)
          : FailureResult<void>(_startFailure(refused));
    } on platform.MobileScannerException catch (error) {
      return FailureResult<void>(_startFailure(error));
    } on Object {
      // Any other start error (no camera, an unsupported browser) still
      // leaves the identifier to be typed.
      return FailureResult<void>(
        ProviderFailure(localizedMessage: Copy.messages.barcodeUnavailable),
      );
    }
  }

  /// A refused camera can be allowed; anything else leaves typing.
  Failure _startFailure(platform.MobileScannerException error) {
    return error.errorCode == platform.MobileScannerErrorCode.permissionDenied
        ? PermissionFailure(
            localizedMessage: Copy.messages.barcodeUnavailable,
            localizedRecovery: Copy.messages.barcodeAllowCamera,
          )
        : ProviderFailure(localizedMessage: Copy.messages.barcodeUnavailable);
  }

  void _decoded(platform.BarcodeCapture capture) {
    for (final platform.Barcode code in capture.barcodes) {
      final String? value = code.rawValue;
      if (value != null && value.isNotEmpty && !_hits.isClosed) {
        _hits.add(BarcodeHit(rawValue: value, format: code.format.name));
      }
    }
  }

  @override
  Future<Result<void>> stop() async {
    try {
      await _subscription?.cancel();
      _subscription = null;
      final platform.MobileScannerController? camera = _camera;
      _camera = null;
      await camera?.dispose();
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(Failure.from(error));
    }
  }

  @override
  Future<void> setTorch(bool on) async {
    if (!torchSupported || torchOn == on) {
      return;
    }
    try {
      await _camera?.toggleTorch();
    } on Object {
      // A torch that stops answering keeps its last state.
    }
  }
}
