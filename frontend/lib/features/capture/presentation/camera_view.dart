import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/copy/copy.dart';

/// Live camera preview sized from the service report.
final class CameraView extends StatefulWidget {
  /// Creates a view over [camera].
  const CameraView({required this.camera, this.gridOverlay = false, super.key});

  /// Camera port.
  final CameraService camera;

  /// Composition grid when enabled.
  final bool gridOverlay;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraPreviewState _state = CameraPreviewState.starting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.camera.previewState.listen((CameraPreviewState next) {
      if (mounted) {
        setState(() => _state = next);
      }
    });
    widget.camera.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.camera.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.camera.pause();
    } else if (state == AppLifecycleState.resumed) {
      widget.camera.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = widget.camera.previewSize;
    return Semantics(
      label: Copy.captureTitle,
      child: AspectRatio(
        aspectRatio: size.width <= 0 || size.height <= 0
            ? 4 / 3
            : size.width / size.height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(
              color: switch (_state) {
                CameraPreviewState.starting => AppColors.dark.surfaceVariant,
                CameraPreviewState.running => AppColors.dark.background,
                CameraPreviewState.failed => AppColors.dark.danger,
              },
              child: Center(
                child: Text(
                  _state.name,
                  style: AppText.caption.copyWith(
                    color: AppColors.dark.onSurface,
                  ),
                ),
              ),
            ),
            if (widget.gridOverlay || widget.camera.gridEnabled)
              const CustomPaint(painter: _GridPainter()),
          ],
        ),
      ),
    );
  }
}

final class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.dark.outline
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final double dx = size.width * i / 3;
      final double dy = size.height * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
