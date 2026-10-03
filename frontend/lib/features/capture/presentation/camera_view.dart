import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/camera/camera.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import 'live_camera_controller.dart';
import 'live_camera_state.dart';

/// The live preview: starting, running or failed (FE-STATE-11), with the
/// grid, tap to focus and pinch to zoom. The camera is released while the
/// app is in the background and opened again on return (step 3).
final class CameraView extends ConsumerStatefulWidget {
  /// Creates a view over [camera].
  const CameraView({required this.camera, super.key});

  /// The running preview, whichever camera draws it.
  static const Key previewKey = ValueKey<String>('camera-preview');

  /// Camera port.
  final CameraService camera;

  @override
  ConsumerState<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<CameraView>
    with WidgetsBindingObserver {
  /// The zoom a pinch started from, so one pinch never compounds.
  double _pinchFrom = 1;

  LiveCameraController get _controller =>
      ref.read(liveCameraControllerProvider(widget.camera).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraPreviewState preview = ref
        .read(liveCameraControllerProvider(widget.camera))
        .preview;
    switch (state) {
      case AppLifecycleState.inactive:
        // The first-run permission prompt makes the app inactive while the
        // camera is still opening; only a running preview is released.
        if (preview == CameraPreviewState.running) {
          unawaited(_controller.pause());
        }
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        unawaited(_controller.pause());
      case AppLifecycleState.resumed:
        unawaited(_controller.resume());
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final LiveCameraState view = ref.watch(
      liveCameraControllerProvider(widget.camera),
    );
    return switch (view.preview) {
      CameraPreviewState.starting => const Center(
        child: AppSkeleton(shape: SkeletonShape.card, count: 1),
      ),
      CameraPreviewState.failed => Center(
        child: SingleChildScrollView(
          child: AppErrorState(
            failure:
                view.failure ??
                ProviderFailure(message: localCopy.photoNoCamera),
            onRetry: () => unawaited(_controller.start()),
          ),
        ),
      ),
      CameraPreviewState.running => _running(context, view),
    };
  }

  Widget _running(BuildContext context, LiveCameraState view) {
    final CameraService camera = widget.camera;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LocalizedCopy localCopy = Copy.of(context);

        final Widget preview = switch (camera) {
          // The plug-in preview sizes and rotates itself.
          final CameraPreviewSurface surface => surface.buildPreview(),
          _ => AspectRatio(
            aspectRatio: _aspect(camera.previewSize, constraints),
            child: ColoredBox(color: context.colors.onSurface),
          ),
        };
        return Center(
          child: Semantics(
            label: localCopy.captureCameraTitle,
            // The builder's size is the preview's, so a tap is measured
            // against the image rather than the space around it.
            child: Builder(
              builder: (BuildContext surface) => GestureDetector(
                key: CameraView.previewKey,
                onTapUp: (TapUpDetails details) => _focus(surface, details),
                onScaleStart: (ScaleStartDetails _) => _pinchFrom = view.zoom,
                onScaleUpdate: (ScaleUpdateDetails details) {
                  if (details.pointerCount > 1) {
                    unawaited(_controller.zoomTo(_pinchFrom * details.scale));
                  }
                },
                child: Stack(
                  children: <Widget>[
                    preview,
                    if (view.grid)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GridPainter(context.colors.outline),
                        ),
                      ),
                    if (view.focus case final ({double x, double y}) focus)
                      Positioned.fill(child: _FocusRing(focus: focus)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _focus(BuildContext surface, TapUpDetails details) {
    final Size size = surface.size ?? Size.zero;
    if (size.isEmpty) {
      return;
    }
    unawaited(
      _controller.focusAt(
        details.localPosition.dx / size.width,
        details.localPosition.dy / size.height,
      ),
    );
  }
}

/// The sensor's aspect ratio, turned to match the space it is shown in: a
/// portrait surface gets a portrait preview.
double _aspect(Size sensor, BoxConstraints space) {
  if (sensor.isEmpty) {
    return 3 / 4;
  }
  final double long = max(sensor.width, sensor.height);
  final double short = min(sensor.width, sensor.height);
  final bool portrait = space.maxHeight > space.maxWidth;
  return portrait ? short / long : long / short;
}

/// Marks where the lens was asked to focus.
final class _FocusRing extends StatelessWidget {
  const _FocusRing({required this.focus});

  final ({double x, double y}) focus;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return Semantics(
      container: true,
      label: localCopy.captureFocus,
      child: Align(
        alignment: Alignment(focus.x * 2 - 1, focus.y * 2 - 1),
        child: SizedBox.square(
          dimension: Sizes.minTapTarget,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: context.colors.warning,
                width: Space.x0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _GridPainter extends CustomPainter {
  const _GridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final double dx = size.width * i / 3;
      final double dy = size.height * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}
