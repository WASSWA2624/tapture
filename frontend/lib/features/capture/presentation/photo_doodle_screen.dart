import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_ink_picker.dart';
import 'package:tapture/core/widgets/markup_stroke.dart';
import 'package:tapture/core/widgets/photo_markup.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/photo_frame.dart';

/// Freehand drawing in a chosen ink and size that saves a derived photo
/// (FBK0000151).
final class PhotoDoodleScreen extends StatefulWidget {
  /// Creates a drawing screen.
  const PhotoDoodleScreen({
    required this.photo,
    required this.bytes,
    required this.onDrawn,
    this.ink = MarkupInk.red,
    this.size = 1,
    this.onStyle,
    super.key,
  });

  /// Source photo. Its bytes stay immutable.
  final PhotoDraft photo;

  /// Pixels to draw on.
  final Uint8List bytes;

  /// Derived draft and PNG, after the write is ready for the caller to store.
  final void Function(PhotoDraft draft, Uint8List png) onDrawn;

  /// The ink the pen starts with.
  final MarkupInk ink;

  /// The size index the pen starts with.
  final int size;

  /// Called with each new ink and size, so the caller can offer them next
  /// time.
  final void Function(MarkupInk ink, int size)? onStyle;

  @override
  State<PhotoDoodleScreen> createState() => _PhotoDoodleScreenState();
}

class _PhotoDoodleScreenState extends State<PhotoDoodleScreen> {
  final List<MarkupStroke> _strokes = <MarkupStroke>[];
  MarkupStroke? _current;
  late MarkupInk _ink = widget.ink;
  late int _size = widget.size;
  Size? _photoSize;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_readSize());
  }

  Future<void> _readSize() async {
    final Size? size = await PhotoFrame.sizeOf(widget.bytes);
    if (!mounted) {
      return;
    }
    setState(() {
      _photoSize = size;
      if (size == null) {
        _error = Copy.photoUnreadable;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size? photoSize = _photoSize;
    final Widget controls = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.x2),
            child: Text(_error!),
          ),
        AppInkPicker(
          ink: _ink,
          size: _size,
          onInk: (MarkupInk ink) => _style(ink, _size),
          onSize: (int size) => _style(_ink, size),
        ),
        const SizedBox(height: Space.x2),
        AppButton(
          label: Copy.save,
          busy: _busy,
          onPressed: _busy || _strokes.isEmpty
              ? null
              : () => unawaited(_save()),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(Copy.photoDraw),
        actions: <Widget>[
          AppIconButton(
            icon: AppIcons.undo,
            tooltip: Copy.photoUndoDraw,
            semanticLabel: Copy.photoUndoDraw,
            onPressed: _strokes.isEmpty && _current == null ? null : _undo,
          ),
          AppIconButton(
            icon: AppIcons.delete,
            tooltip: Copy.photoClearDraw,
            semanticLabel: Copy.photoClearDraw,
            onPressed: _strokes.isEmpty ? null : _clear,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints limits) {
            final bool wide = limits.maxWidth > limits.maxHeight;
            final Widget canvas = photoSize == null
                ? Center(child: Text(_error == null ? Copy.loading : ''))
                : _canvas(photoSize);
            final Widget panel = SingleChildScrollView(
              key: const ValueKey<String>('doodle-controls'),
              padding: const EdgeInsets.all(Space.x2),
              child: controls,
            );
            // The photo takes what the controls leave; the controls scroll
            // when text is large, so the picker and Save stay reachable.
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(child: canvas),
                      SizedBox(
                        width: limits.maxWidth * AppConstants.markup.panelShare,
                        child: panel,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(child: canvas),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              limits.maxHeight * AppConstants.markup.panelShare,
                        ),
                        child: panel,
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _canvas(Size photoSize) {
    final int turns = PhotoFrame.quarterTurns(widget.photo.rotationDegrees);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints limits) {
        final Rect photo = PhotoFrame.fit(limits.biggest, photoSize, turns);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (DragStartDetails details) =>
              _start(photo, details.localPosition),
          onPanUpdate: (DragUpdateDetails details) =>
              _extend(photo, details.localPosition),
          onPanEnd: (_) => _end(),
          child: Stack(
            children: <Widget>[
              Positioned.fromRect(
                rect: photo,
                child: RotatedBox(
                  quarterTurns: turns,
                  child: Image.memory(
                    widget.bytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: photo,
                child: CustomPaint(
                  key: const ValueKey<String>('doodle-strokes'),
                  painter: _StrokePainter(
                    strokes: <MarkupStroke>[..._strokes, ?_current],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _style(MarkupInk ink, int size) {
    setState(() {
      _ink = ink;
      _size = size;
    });
    widget.onStyle?.call(ink, size);
  }

  /// Starts a stroke in the current ink and size. A touch outside the photo
  /// starts none.
  void _start(Rect photo, Offset local) {
    if (!photo.contains(local)) {
      return;
    }
    setState(() {
      _current = MarkupStroke(
        points: <Offset>[_fraction(photo, local)],
        ink: _ink,
        size: _size,
      );
    });
  }

  void _extend(Rect photo, Offset local) {
    final MarkupStroke? current = _current;
    if (current == null) {
      return;
    }
    setState(() => _current = current.adding(_fraction(photo, local)));
  }

  void _end() {
    final MarkupStroke? current = _current;
    if (current == null || current.points.length < 2) {
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

  Offset _fraction(Rect photo, Offset local) {
    if (photo.width <= 0 || photo.height <= 0) {
      return Offset.zero;
    }
    return Offset(
      ((local.dx - photo.left) / photo.width).clamp(0.0, 1.0),
      ((local.dy - photo.top) / photo.height).clamp(0.0, 1.0),
    );
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final Result<Uint8List> drawn = await PhotoMarkup.draw(
      widget.bytes,
      List<MarkupStroke>.of(_strokes),
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

/// Paints each stroke in its own ink, as wide relative to the shown photo as
/// the saved photo will have it (AppConstants.markup).
class _StrokePainter extends CustomPainter {
  _StrokePainter({required this.strokes});

  final List<MarkupStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final MarkupStroke stroke in strokes) {
      if (stroke.points.length < 2) {
        continue;
      }
      final Paint paint = Paint()
        ..color = stroke.ink.color
        ..strokeWidth = stroke.widthFraction * size.shortestSide
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final Offset first = stroke.points.first;
      final Path path = Path()
        ..moveTo(first.dx * size.width, first.dy * size.height);
      for (final Offset point in stroke.points.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter oldDelegate) => true;
}
