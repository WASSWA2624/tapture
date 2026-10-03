import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/image_redaction.dart';
import 'package:tapture/core/widgets/state_refresh.dart';

/// Marks regions on the actual upright photo, independently of preview size.
final class RedactionEditor extends StatefulWidget {
  const RedactionEditor({
    required this.marks,
    required this.onChanged,
    this.bytes,
    this.imageWidth = 1,
    this.imageHeight = 1,
    this.failure,
    this.empty = false,
    super.key,
  });

  final Uint8List? bytes;
  final int imageWidth;
  final int imageHeight;
  final List<RedactionMark> marks;
  final ValueChanged<List<RedactionMark>> onChanged;
  final String? failure;
  final bool empty;

  /// Compatibility wrapper; protection failures cannot return clear pixels.
  static Future<Uint8List> burn(
    Uint8List original,
    List<RedactionMark> marks,
  ) async {
    return switch (await ImageRedaction.burn(original, marks)) {
      Success<Uint8List>(:final Uint8List value) => value,
      FailureResult<Uint8List>(:final Failure failure) => throw failure,
    };
  }

  @override
  State<RedactionEditor> createState() => _RedactionEditorState();
}

final class _RedactionEditorState extends State<RedactionEditor>
    with StateRefresh<RedactionEditor> {
  Offset? _start;
  Offset? _end;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (widget.failure != null) return Text(widget.failure!);
    if (widget.empty || widget.bytes == null) {
      return Text(localCopy.redactionEmptyMessage);
    }
    return Semantics(
      label: localCopy.redactionHint,
      child: AspectRatio(
        aspectRatio: widget.imageWidth / widget.imageHeight,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            Offset point(Offset value) => Offset(
              (value.dx / box.maxWidth).clamp(0, 1),
              (value.dy / box.maxHeight).clamp(0, 1),
            );
            return GestureDetector(
              key: const ValueKey<String>('redaction-surface'),
              behavior: HitTestBehavior.opaque,
              onPanStart: (DragStartDetails details) => refresh(() {
                _start = point(details.localPosition);
                _end = _start;
              }),
              onPanUpdate: (DragUpdateDetails details) => refresh(() {
                _end = point(details.localPosition);
              }),
              onPanCancel: () => refresh(() {
                _start = null;
                _end = null;
              }),
              onPanEnd: (_) {
                final ImageRect? mark = _selection;
                if (mark != null && mark.width > 0 && mark.height > 0) {
                  widget.onChanged(<ImageRect>[...widget.marks, mark]);
                }
                refresh(() {
                  _start = null;
                  _end = null;
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.memory(
                    widget.bytes!,
                    key: const ValueKey<String>('redaction-photo'),
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _MarksPainter(<ImageRect>[
                        ...widget.marks,
                        if (_selection case final ImageRect mark) mark,
                      ], Theme.of(context).colorScheme.scrim),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  ImageRect? get _selection {
    final Offset? start = _start;
    final Offset? end = _end;
    if (start == null || end == null) return null;
    final Rect rect = Rect.fromPoints(start, end);
    return (x: rect.left, y: rect.top, width: rect.width, height: rect.height);
  }
}

/// Stored normalized mark reused by preview, analysis and export.
typedef RedactionMark = ImageRect;

final class _MarksPainter extends CustomPainter {
  const _MarksPainter(this.marks, this.color);
  final List<ImageRect> marks;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    for (final ImageRect mark in marks) {
      canvas.drawRect(
        Rect.fromLTWH(
          mark.x * size.width,
          mark.y * size.height,
          mark.width * size.width,
          mark.height * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MarksPainter oldDelegate) =>
      oldDelegate.marks != marks || oldDelegate.color != color;
}
