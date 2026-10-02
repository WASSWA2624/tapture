import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as platform;
import 'package:tapture/core/camera/camera_preview_surface.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'web_barcode_support.dart'
    if (dart.library.js_interop) 'web_barcode_support_web.dart'
    as web;

part 'barcode_hit.dart';
part 'device_barcode_scanner.dart';

/// Decodes barcodes from a camera stream. Features never call a scanner
/// plugin (FE-STR-11).
abstract interface class BarcodeScannerService {
  /// Creates the maintained platform scanner; unsupported devices allow typing.
  factory BarcodeScannerService() {
    return kIsWeb ||
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS
        ? _DeviceBarcodeScanner(open: _openController)
        : const BarcodeScannerService.unavailable();
  }

  /// The `mobile_scanner` scanner over the controller [controller] makes, so
  /// tests can drive permission errors, decodes and the torch.
  @visibleForTesting
  factory BarcodeScannerService.device({
    platform.MobileScannerController Function()? controller,
  }) {
    return _DeviceBarcodeScanner(open: controller ?? _openController);
  }

  /// Unavailable stand-in until [main] overrides.
  const factory BarcodeScannerService.unavailable() =
      _UnavailableBarcodeScanner;

  /// The same-origin path of the decoder script the web scanner loads in a
  /// browser without a native barcode detector. Nothing is fetched from a
  /// third-party origin (§7.1).
  static const String webDecoderScript = 'vendor/zxing/zxing.min.js';

  /// The scan region's side as a share of the preview's shorter side. The
  /// screen draws the region, centred, and only codes inside it are read.
  static const double scanRegionShare = 0.6;

  /// Whether torch can be toggled.
  bool get torchSupported;

  /// Whether the torch is on.
  bool get torchOn;

  /// Decoded values from the live stream inside the scan region. A frame the
  /// decoder could not read arrives as a [ProviderFailure] error carrying
  /// [Copy.barcodeUnreadable]; scanning carries on.
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

  static final ProviderFailure _fail = ProviderFailure(
    localizedMessage: Copy.messages.barcodeUnavailable,
  );

  @override
  bool get torchSupported => false;

  @override
  bool get torchOn => false;

  @override
  Stream<BarcodeHit> get hits => const Stream<BarcodeHit>.empty();

  @override
  Future<Result<void>> start() async => FailureResult<void>(_fail);

  @override
  Future<Result<void>> stop() async => const Success<void>(null);

  @override
  Future<void> setTorch(bool on) async {}
}
