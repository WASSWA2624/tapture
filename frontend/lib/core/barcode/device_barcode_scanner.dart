part of 'barcode_scanner_service.dart';

final class _DeviceBarcodeScanner
    implements BarcodeScannerService, CameraPreviewSurface {
  platform.MobileScannerController? _camera;
  StreamSubscription<platform.BarcodeCapture>? _subscription;
  final StreamController<BarcodeHit> _hits =
      StreamController<BarcodeHit>.broadcast();

  platform.MobileScannerController get _controller =>
      _camera ??= platform.MobileScannerController(autoStart: false);

  @override
  Stream<BarcodeHit> get hits => _hits.stream;
  @override
  bool get torchSupported =>
      _camera?.value.torchState != platform.TorchState.unavailable;
  @override
  bool get torchOn => _camera?.value.torchState == platform.TorchState.on;

  @override
  Widget buildPreview() => platform.MobileScanner(
    controller: _controller,
    tapToFocus: true,
    errorBuilder: (_, _) => const Center(child: Text(Copy.barcodeUnavailable)),
  );

  @override
  Future<Result<void>> start() async {
    try {
      _subscription ??= _controller.barcodes.listen(
        (platform.BarcodeCapture capture) {
          for (final platform.Barcode code in capture.barcodes) {
            final String? value = code.rawValue;
            if (value != null && value.isNotEmpty) {
              _hits.add(BarcodeHit(rawValue: value, format: code.format.name));
            }
          }
        },
        onError: (Object _, StackTrace _) {
          // An unreadable frame leaves scanning active; the user can type instead.
        },
      );
      await _controller.start();
      return const Success<void>(null);
    } on platform.MobileScannerException catch (error) {
      return FailureResult<void>(
        error.errorCode == platform.MobileScannerErrorCode.permissionDenied
            ? const PermissionFailure(message: Copy.barcodeUnavailable)
            : const ProviderFailure(message: Copy.barcodeUnavailable),
      );
    } on Object catch (error) {
      return FailureResult<void>(Failure.from(error));
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
    if (torchSupported && torchOn != on) await _camera?.toggleTorch();
  }
}
