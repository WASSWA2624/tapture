import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/barcode/barcode.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/feedback/haptics.dart';

import 'barcode_scan_state.dart';

export 'barcode_scan_state.dart';

/// One scan: the first decoded code is held, once, until it is confirmed or
/// cleared for a rescan; a scanner that cannot start says why, and the
/// identifier can still be typed (§25). In count mode the scanner stays open
/// and every new code is added to a running count instead, with a repeat of
/// the same code inside the repeat window dropped and the last scan undoable.
final class BarcodeScannerController extends Notifier<BarcodeScanState> {
  /// Creates the controller for [scanner] (family argument).
  BarcodeScannerController(this.scanner);

  /// The scanner this screen reads from.
  final BarcodeScannerService scanner;

  StreamSubscription<BarcodeHit>? _hits;
  StreamSubscription<BarcodeHit>? _counts;

  @override
  BarcodeScanState build() {
    unawaited(_hits?.cancel());
    unawaited(_counts?.cancel());
    _hits = scanner.hits.listen(_decoded, onError: _unreadable);
    _counts = BarcodeScannerService.debounceRepeats(
      scanner.hits,
    ).listen(_counted, onError: (Object _) {});
    ref.onDispose(() {
      unawaited(_hits?.cancel());
      unawaited(_counts?.cancel());
      _hits = null;
      _counts = null;
      unawaited(scanner.stop());
    });
    return const BarcodeScanState();
  }

  /// Opens the scanner. A refusal or a missing scanner shows the
  /// unavailable message.
  Future<void> start() async {
    final Result<void> started = await scanner.start();
    if (!ref.mounted) {
      return;
    }
    state = switch (started) {
      FailureResult<void>(:final Failure failure) => state.copyWith(
        failure: failure,
        started: false,
        torchOn: false,
        clearCode: true,
        unreadable: false,
      ),
      Success<void>() => state.copyWith(
        clearFailure: true,
        started: true,
        torchOn: scanner.torchOn,
      ),
    };
  }

  /// Clears the held code so the next one can be read.
  void rescan() {
    state = state.copyWith(clearCode: true, unreadable: false);
  }

  /// Switches between holding one code and counting every code.
  void setCounting(bool on) {
    state = state.copyWith(counting: on, clearCode: true, unreadable: false);
  }

  /// Takes the last counted scan back off the count.
  void undoLast() {
    if (state.counted.isEmpty) {
      return;
    }
    state = state.copyWith(
      counted: state.counted.sublist(0, state.counted.length - 1),
    );
  }

  /// Turns the torch on or off where the scanner has one.
  Future<void> toggleTorch() async {
    await scanner.setTorch(!scanner.torchOn);
    if (ref.mounted) {
      state = state.copyWith(torchOn: scanner.torchOn);
    }
  }

  void _decoded(BarcodeHit hit) {
    if (!ref.mounted || state.counting || state.code != null) {
      return;
    }
    ref.read(hapticsProvider).selection();
    state = state.copyWith(code: hit.rawValue, unreadable: false);
  }

  void _counted(BarcodeHit hit) {
    if (!ref.mounted || !state.counting) {
      return;
    }
    ref.read(hapticsProvider).selection();
    state = state.copyWith(
      counted: <String>[...state.counted, hit.rawValue],
      unreadable: false,
    );
  }

  void _unreadable(Object _) {
    if (!ref.mounted || state.code != null) {
      return;
    }
    state = state.copyWith(unreadable: true);
  }
}

/// One controller per open scanner, released when its screen closes.
final barcodeScannerControllerProvider = NotifierProvider.autoDispose
    .family<BarcodeScannerController, BarcodeScanState, BarcodeScannerService>(
      BarcodeScannerController.new,
    );
