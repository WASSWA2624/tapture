import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/core/barcode/barcode_scanner_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';

/// Continuous scan with debounce, running count and undo.
final class BarcodeContinuousMode extends StatefulWidget {
  /// Creates continuous mode.
  const BarcodeContinuousMode({
    required this.scanner,
    this.debounce = const Duration(milliseconds: 800),
    super.key,
  });

  /// Scanner port.
  final BarcodeScannerService scanner;

  /// Repeat-code window.
  final Duration debounce;

  @override
  State<BarcodeContinuousMode> createState() => _BarcodeContinuousModeState();
}

class _BarcodeContinuousModeState extends State<BarcodeContinuousMode> {
  final List<String> _scans = <String>[];
  StreamSubscription<BarcodeHit>? _sub;

  @override
  void initState() {
    super.initState();
    _sub =
        BarcodeScannerService.debounceRepeats(
          widget.scanner.hits,
          window: widget.debounce,
        ).listen((BarcodeHit hit) {
          setState(() => _scans.add(hit.rawValue));
        });
    unawaited(widget.scanner.start());
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.scanner.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(Copy.barcodeScanCount(_scans.length)),
        Expanded(
          child: ListView(
            children: <Widget>[
              for (final String code in _scans) ListTile(title: Text(code)),
            ],
          ),
        ),
        AppButton(
          label: Copy.barcodeUndoLast,
          onPressed: _scans.isEmpty
              ? null
              : () => setState(() => _scans.removeLast()),
        ),
      ],
    );
  }
}
