import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

part 'barcode_hit.dart';

/// Decodes barcodes from a camera stream. Features never call a scanner
/// plugin (FE-STR-11).
abstract interface class BarcodeScannerService {
  /// Unavailable stand-in until [main] overrides.
  const factory BarcodeScannerService.unavailable() =
      _UnavailableBarcodeScanner;

  /// Scripted stand-in that emits [hits] then optionally completes.
  factory BarcodeScannerService.fake({
    List<BarcodeHit> hits = const <BarcodeHit>[],
    Failure? startFailure,
    bool torchSupported = true,
  }) {
    return _FakeBarcodeScanner(
      hits: hits,
      startFailure: startFailure,
      torchSupported: torchSupported,
    );
  }

  /// Whether torch can be toggled.
  bool get torchSupported;

  /// Whether the torch is on.
  bool get torchOn;

  /// Decoded values from the live stream inside the scan region.
  Stream<BarcodeHit> get hits;

  /// Opens the decoder stream.
  Future<Result<void>> start();

  /// Closes the decoder stream.
  Future<Result<void>> stop();

  /// Toggles torch when supported.
  Future<void> setTorch(bool on);

  /// Drops repeated codes within [window] for continuous counting.
  static Stream<BarcodeHit> debounceRepeats(
    Stream<BarcodeHit> source, {
    Duration window = AppConstants.barcodeRepeatWindow,
  }) {
    BarcodeHit? last;
    DateTime? at;
    return source.where((BarcodeHit hit) {
      final DateTime now = DateTime.now();
      if (last != null &&
          last!.rawValue == hit.rawValue &&
          at != null &&
          now.difference(at!) < window) {
        return false;
      }
      last = hit;
      at = now;
      return true;
    });
  }
}

/// Process-wide scanner. Default is unavailable.
final Provider<BarcodeScannerService> barcodeScannerServiceProvider =
    Provider<BarcodeScannerService>((Ref _) {
      return const BarcodeScannerService.unavailable();
    });

final class _UnavailableBarcodeScanner implements BarcodeScannerService {
  const _UnavailableBarcodeScanner();

  static const ProviderFailure _fail = ProviderFailure(
    message: Copy.barcodeUnavailable,
  );

  @override
  bool get torchSupported => false;

  @override
  bool get torchOn => false;

  @override
  Stream<BarcodeHit> get hits => const Stream<BarcodeHit>.empty();

  @override
  Future<Result<void>> start() async => const FailureResult<void>(_fail);

  @override
  Future<Result<void>> stop() async => const Success<void>(null);

  @override
  Future<void> setTorch(bool on) async {}
}

final class _FakeBarcodeScanner implements BarcodeScannerService {
  _FakeBarcodeScanner({
    required List<BarcodeHit> hits,
    required this.startFailure,
    required this.torchSupported,
  }) : _scripted = hits;

  @override
  final bool torchSupported;
  final List<BarcodeHit> _scripted;
  final Failure? startFailure;

  final StreamController<BarcodeHit> _controller =
      StreamController<BarcodeHit>.broadcast();
  bool _torch = false;

  @override
  bool get torchOn => _torch;

  @override
  Stream<BarcodeHit> get hits => _controller.stream;

  @override
  Future<Result<void>> start() async {
    final Failure? failure = startFailure;
    if (failure != null) {
      return FailureResult<void>(failure);
    }
    for (final BarcodeHit hit in _scripted) {
      if (!_controller.isClosed) {
        _controller.add(hit);
      }
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> stop() async {
    return const Success<void>(null);
  }

  @override
  Future<void> setTorch(bool on) async {
    if (torchSupported) {
      _torch = on;
    }
  }

  /// Tests push extra hits after start.
  void emit(BarcodeHit hit) {
    if (!_controller.isClosed) {
      _controller.add(hit);
    }
  }
}
