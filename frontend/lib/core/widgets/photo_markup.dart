import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Derived photo bytes. Original files are never rewritten (FE-SEC-08).
abstract final class PhotoMarkup {
  /// Encodes the region of [bytes] described by [fraction] of the image.
  ///
  /// A null [fraction] copies the whole frame.
  static Future<Uint8List> crop(Uint8List bytes, Rect? fraction) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image source = frame.image;
    final Rect full = Rect.fromLTWH(
      0,
      0,
      source.width.toDouble(),
      source.height.toDouble(),
    );
    final Rect region = _region(full, fraction);
    final int width = region.width.ceil().clamp(1, source.width);
    final int height = region.height.ceil().clamp(1, source.height);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawImageRect(
      source,
      region,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint(),
    );
    final ui.Image image = await recorder.endRecording().toImage(width, height);
    return _png(image);
  }

  /// Paints [text] on a copy of [bytes].
  static Future<Uint8List> typeOn(Uint8List bytes, String text) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image source = frame.image;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawImage(source, Offset.zero, Paint());
    final ui.ParagraphBuilder builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(fontSize: 24, textAlign: TextAlign.left),
          )
          ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFFFFFFF)))
          ..addText(text);
    final ui.Paragraph paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: source.width.toDouble()));
    canvas.drawParagraph(
      paragraph,
      Offset(8, source.height - paragraph.height - 8),
    );
    final ui.Image image = await recorder.endRecording().toImage(
      source.width,
      source.height,
    );
    return _png(image);
  }
}

Rect _region(Rect full, Rect? fraction) {
  if (fraction == null || fraction.width <= 0 || fraction.height <= 0) {
    return full;
  }
  return Rect.fromLTWH(
    fraction.left * full.width,
    fraction.top * full.height,
    fraction.width * full.width,
    fraction.height * full.height,
  );
}

Future<Uint8List> _png(ui.Image image) async {
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List() ?? Uint8List(0);
}
