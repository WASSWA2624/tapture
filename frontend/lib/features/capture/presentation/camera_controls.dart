import 'package:flutter/material.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/copy/copy.dart';

/// Flash, focus, zoom and grid controls for capture.
final class CameraControls extends StatefulWidget {
  /// Creates controls wired to [camera].
  const CameraControls({
    required this.camera,
    this.onShutter,
    this.onFlashChanged,
    this.onGridChanged,
    super.key,
  });

  /// Camera port.
  final CameraService camera;

  /// Shutter press.
  final VoidCallback? onShutter;

  /// Flash mode after a cycle.
  final ValueChanged<CameraFlashMode>? onFlashChanged;

  /// Grid toggle persistence.
  final ValueChanged<bool>? onGridChanged;

  @override
  State<CameraControls> createState() => _CameraControlsState();
}

class _CameraControlsState extends State<CameraControls> {
  Offset? _focus;

  Future<void> _cycleFlash() async {
    final CameraFlashMode mode = await widget.camera.cycleFlash();
    widget.onFlashChanged?.call(mode);
    setState(() {});
  }

  Future<void> _toggleGrid() async {
    final bool next = !widget.camera.gridEnabled;
    await widget.camera.setGridEnabled(next);
    widget.onGridChanged?.call(next);
    setState(() {});
  }

  Future<void> _zoom(double delta) async {
    await widget.camera.setZoom(widget.camera.zoom + delta);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTapDown: (TapDownDetails details) async {
              final RenderBox box = context.findRenderObject()! as RenderBox;
              final Offset local = box.globalToLocal(details.globalPosition);
              final double x = (local.dx / box.size.width).clamp(0.0, 1.0);
              final double y = (local.dy / box.size.height).clamp(0.0, 1.0);
              await widget.camera.focusAt(x, y);
              setState(() => _focus = local);
            },
            onScaleUpdate: (ScaleUpdateDetails details) async {
              await widget.camera.setZoom(
                widget.camera.zoom * details.scale.clamp(0.5, 2.0),
              );
              setState(() {});
            },
            child: Stack(
              children: <Widget>[
                if (_focus != null)
                  Positioned(
                    left: _focus!.dx - 24,
                    top: _focus!.dy - 24,
                    child: Semantics(
                      label: Copy.captureFocus,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.yellow, width: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Semantics(
              label: Copy.captureFlash,
              button: true,
              child: IconButton(
                iconSize: 28,
                onPressed: _cycleFlash,
                icon: Icon(switch (widget.camera.flashMode) {
                  CameraFlashMode.off => Icons.flash_off,
                  CameraFlashMode.auto => Icons.flash_auto,
                  CameraFlashMode.on => Icons.flash_on,
                }),
              ),
            ),
            Semantics(
              label: Copy.captureGrid,
              button: true,
              child: IconButton(
                iconSize: 28,
                onPressed: _toggleGrid,
                icon: Icon(
                  widget.camera.gridEnabled ? Icons.grid_on : Icons.grid_off,
                ),
              ),
            ),
            Semantics(
              label: Copy.captureZoom,
              button: true,
              child: IconButton(
                iconSize: 28,
                onPressed: () => _zoom(-0.5),
                icon: const Icon(Icons.zoom_out),
              ),
            ),
            Semantics(
              label: Copy.captureZoom,
              button: true,
              child: IconButton(
                iconSize: 28,
                onPressed: () => _zoom(0.5),
                icon: const Icon(Icons.zoom_in),
              ),
            ),
            Semantics(
              label: Copy.captureShutter,
              button: true,
              child: IconButton(
                iconSize: 48,
                onPressed: widget.onShutter,
                icon: const Icon(Icons.camera),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
