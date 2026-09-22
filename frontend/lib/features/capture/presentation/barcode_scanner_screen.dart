import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/core/barcode/barcode_scanner_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';

/// One-handed barcode scan with confirm / rescan.
final class BarcodeScannerScreen extends StatefulWidget {
  /// Creates a scanner screen.
  const BarcodeScannerScreen({
    required this.scanner,
    required this.onConfirmed,
    super.key,
  });

  /// Scanner port.
  final BarcodeScannerService scanner;

  /// Confirmed raw value.
  final ValueChanged<String> onConfirmed;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  String? _decoded;
  String? _error;
  StreamSubscription<BarcodeHit>? _sub;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    _sub = widget.scanner.hits.listen((BarcodeHit hit) {
      setState(() {
        _decoded = hit.rawValue;
        _error = null;
      });
    });
    final Result<void> started = await widget.scanner.start();
    started.fold((Failure failure) {
      setState(() => _error = failure.message);
    }, (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.scanner.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Copy.barcodeNoCode),
        actions: <Widget>[
          if (widget.scanner.torchSupported)
            IconButton(
              onPressed: () => widget.scanner.setTorch(!widget.scanner.torchOn),
              icon: Icon(
                widget.scanner.torchOn ? Icons.flash_on : Icons.flash_off,
              ),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(_error ?? _decoded ?? Copy.barcodeNoCode),
            ),
          ),
          if (_decoded != null) ...<Widget>[
            AppButton(
              label: Copy.barcodeConfirm,
              onPressed: () => widget.onConfirmed(_decoded!),
            ),
            AppButton(
              label: Copy.barcodeRescan,
              onPressed: () => setState(() => _decoded = null),
            ),
          ],
        ],
      ),
    );
  }
}
