import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/barcode/barcode_scanner_service.dart';
import 'package:tapture/core/camera/camera_preview_surface.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';

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
    unawaited(_start());
  }

  Future<void> _start() async {
    _sub = widget.scanner.hits.listen((BarcodeHit hit) {
      if (!mounted || _decoded != null) return;
      unawaited(HapticFeedback.selectionClick());
      setState(() {
        _decoded = hit.rawValue;
        _error = null;
      });
    });
    final Result<void> started = await widget.scanner.start();
    if (!mounted) return;
    started.fold((Failure failure) {
      setState(() => _error = failure.message);
    }, (_) => setState(() {}));
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(widget.scanner.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Copy.barcodeNoCode),
        actions: <Widget>[
          if (widget.scanner.torchSupported)
            AppIconButton(
              tooltip: Copy.captureFlash,
              semanticLabel: Copy.captureFlash,
              onPressed: () async {
                await widget.scanner.setTorch(!widget.scanner.torchOn);
                if (mounted) setState(() {});
              },
              icon: widget.scanner.torchOn
                  ? AppIcons.flashOn
                  : AppIcons.flashOff,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (_error == null && widget.scanner is CameraPreviewSurface)
                    (widget.scanner as CameraPreviewSurface).buildPreview(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(Space.x3),
                        child: Text(_error ?? _decoded ?? Copy.barcodeNoCode),
                      ),
                    ),
                  ),
                ],
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
      ),
    );
  }
}
