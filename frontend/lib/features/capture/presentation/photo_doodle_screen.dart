import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/photo_markup.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

/// Freehand drawing that saves a derived photo.
final class PhotoDoodleScreen extends StatefulWidget {
  /// Creates a drawing screen.
  const PhotoDoodleScreen({
    required this.photo,
    required this.bytes,
    required this.onDrawn,
    super.key,
  });

  /// Source photo. Its bytes stay immutable.
  final PhotoDraft photo;

  /// Pixels to draw on.
  final Uint8List bytes;

  /// Derived draft and PNG, after the write is ready for the caller to store.
  final void Function(PhotoDraft draft, Uint8List png) onDrawn;

  @override
  State<PhotoDoodleScreen> createState() => _PhotoDoodleScreenState();
}

class _PhotoDoodleScreenState extends State<PhotoDoodleScreen> {
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset>? _current;
  String? _error;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text(Copy.photoDraw),
        actions: <Widget>[
          AppIconButton(
            icon: Icons.undo,
            tooltip: Copy.photoUndoDraw,
            semanticLabel: Copy.photoUndoDraw,
            onPressed: _strokes.isEmpty && _current == null ? null : _undo,
          ),
          AppIconButton(
            icon: Icons.delete_outline,
            tooltip: Copy.photoClearDraw,
            semanticLabel: Copy.photoClearDraw,
            onPressed: _strokes.isEmpty ? null : _clear,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints limits) {
                return GestureDetector(
                  onPanStart: (DragStartDetails details) =>
                      _start(limits.biggest, details.localPosition),
                  onPanUpdate: (DragUpdateDetails details) =>
                      _extend(limits.biggest, details.localPosition),
                  onPanEnd: (_) => _end(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Center(
                        child: RotatedBox(
                          quarterTurns:
                              ((widget.photo.rotationDegrees % 360) + 360) %
                              360 ~/
                              90,
                          child: Image.memory(
                            widget.bytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      CustomPaint(
                        painter: _StrokePainter(
                          strokes: <List<Offset>>[
                            ..._strokes,
                            ?_current,
                          ],
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(Space.x2),
              child: Text(_error!),
            ),
          Padding(
            padding: const EdgeInsets.all(Space.x2),
            child: AppButton(
              label: Copy.save,
              busy: _busy,
              onPressed: _busy || _strokes.isEmpty
                  ? null
                  : () => unawaited(_save()),
            ),
          ),
        ],
      ),
    );
  }

  void _start(Size size, Offset local) {
    setState(() => _current = <Offset>[_fraction(size, local)]);
  }

  void _extend(Size size, Offset local) {
    final List<Offset>? current = _current;
    if (current == null) {
      return;
    }
    setState(() => current.add(_fraction(size, local)));
  }

  void _end() {
    final List<Offset>? current = _current;
    if (current == null || current.length < 2) {
      setState(() => _current = null);
      return;
    }
    setState(() {
      _strokes.add(current);
      _current = null;
    });
  }

  void _undo() {
    setState(() {
      if (_current != null) {
        _current = null;
        return;
      }
      if (_strokes.isNotEmpty) {
        _strokes.removeLast();
      }
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _current = null;
    });
  }

  Offset _fraction(Size size, Offset local) {
    if (size.width == 0 || size.height == 0) {
      return Offset.zero;
    }
    return Offset(
      (local.dx / size.width).clamp(0.0, 1.0),
      (local.dy / size.height).clamp(0.0, 1.0),
    );
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final Result<Uint8List> drawn = await PhotoMarkup.draw(
      widget.bytes,
      <List<List<double>>>[
        for (final List<Offset> stroke in _strokes)
          <List<double>>[
            for (final Offset point in stroke) <double>[point.dx, point.dy],
          ],
      ],
      rotationDegrees: widget.photo.rotationDegrees,
    );
    if (!mounted) {
      return;
    }
    switch (drawn) {
      case FailureResult<Uint8List>(:final Failure failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
      case Success<Uint8List>(:final Uint8List value):
        final String id = UuidV7Service(const SystemClock()).newId();
        widget.onDrawn(
          widget.photo.copyWith(
            id: id,
            relativePath: 'photos/$id.png',
            storedFilename: '$id.png',
            originalFilename: '$id.png',
            mimeType: 'image/png',
            derivedFrom: widget.photo.id,
            rotationDegrees: 0,
            capturedAt: const SystemClock().nowUtc(),
          ),
          value,
        );
        setState(() => _busy = false);
    }
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter({required this.strokes, required this.color});

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = Space.x1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final List<Offset> stroke in strokes) {
      if (stroke.length < 2) {
        continue;
      }
      final Path path = Path()
        ..moveTo(stroke.first.dx * size.width, stroke.first.dy * size.height);
      for (final Offset point in stroke.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter oldDelegate) => true;
}
