import 'dart:async';

import 'package:tapture/core/barcode/barcode_scanner_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// A scanner a test drives by hand: it decodes what the test says it saw,
/// when the test says so, and counts how often it was started and stopped
/// (FE-TEST-03).
final class FakeBarcodeScannerService implements BarcodeScannerService {
  /// Creates the fake. [hits] are decoded as soon as [start] succeeds;
  /// [startFailure] makes every start fail instead.
  FakeBarcodeScannerService({
    List<BarcodeHit> hits = const <BarcodeHit>[],
    this.startFailure,
    this.torchSupported = true,
  }) : _scripted = hits;

  /// What [start] returns instead of opening the stream.
  final Failure? startFailure;

  @override
  final bool torchSupported;

  final List<BarcodeHit> _scripted;
  final StreamController<BarcodeHit> _hits =
      StreamController<BarcodeHit>.broadcast();
  bool _torch = false;

  /// How many times [start] was called.
  int startCalls = 0;

  /// How many times [stop] was called.
  int stopCalls = 0;

  @override
  bool get torchOn => _torch;

  @override
  Stream<BarcodeHit> get hits => _hits.stream;

  @override
  Future<Result<void>> start() async {
    startCalls += 1;
    final Failure? refused = startFailure;
    if (refused != null) {
      return FailureResult<void>(refused);
    }
    for (final BarcodeHit hit in _scripted) {
      emit(hit);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> stop() async {
    stopCalls += 1;
    return const Success<void>(null);
  }

  @override
  Future<void> setTorch(bool on) async {
    if (torchSupported) {
      _torch = on;
    }
  }

  /// Decodes [hit] now, as a code entering the scan region would.
  void emit(BarcodeHit hit) {
    if (!_hits.isClosed) {
      _hits.add(hit);
    }
  }

  /// Reports a frame the decoder could not read, as the device scanner does.
  void fail(Failure failure) {
    if (!_hits.isClosed) {
      _hits.addError(failure);
    }
  }

  /// Releases the stream. Tests call this from `tearDown`.
  void dispose() {
    _hits.close();
  }
}
