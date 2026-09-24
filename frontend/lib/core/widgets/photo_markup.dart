import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Derived photo bytes. Original files are never rewritten (FE-SEC-08).
abstract final class PhotoMarkup {
  /// Crops [bytes] to [fraction] of the rotated frame.
  ///
  /// [fraction] is in the space the operator sees after [rotationDegrees].
  /// A null [fraction] keeps the whole rotated frame.
  static Future<Result<Uint8List>> crop(
    Uint8List bytes,
    Rect? fraction, {
    int rotationDegrees = 0,
  }) {
    return runIsolate(_cropJob, <Object?>[
      bytes,
      fraction?.left,
      fraction?.top,
      fraction?.width,
      fraction?.height,
      rotationDegrees,
    ]);
  }

  /// Paints [text] on a copy of [bytes], with a dark backing so it stays readable.
  static Future<Result<Uint8List>> typeOn(
    Uint8List bytes,
    String text, {
    int rotationDegrees = 0,
  }) {
    return runIsolate(_typeJob, <Object?>[bytes, text, rotationDegrees]);
  }

  /// Strokes [points] onto a copy. Each stroke is a list of x,y fractions.
  static Future<Result<Uint8List>> draw(
    Uint8List bytes,
    List<List<List<double>>> strokes, {
    int rotationDegrees = 0,
  }) {
    return runIsolate(_drawJob, <Object?>[bytes, strokes, rotationDegrees]);
  }
}

Future<Uint8List> _cropJob(List<Object?> job) async {
  IsolateRunner.reportProgress(0);
  final Uint8List bytes = _encoded(
    _crop(
      _oriented(_decode(job[0]! as Uint8List), job[5]! as int),
      job[1] as double?,
      job[2] as double?,
      job[3] as double?,
      job[4] as double?,
    ),
  );
  IsolateRunner.reportProgress(1);
  return bytes;
}

Future<Uint8List> _typeJob(List<Object?> job) async {
  IsolateRunner.reportProgress(0);
  final img.Image image = _oriented(
    _decode(job[0]! as Uint8List),
    job[2]! as int,
  );
  final String text = (job[1]! as String).trim();
  if (text.isEmpty) {
    throw const ValidationFailure(
      message: 'Type the words to place on this photo.',
      recoveryAction: 'Enter text, then save the photo.',
    );
  }
  _paintText(image, text);
  final Uint8List bytes = _encoded(image);
  IsolateRunner.reportProgress(1);
  return bytes;
}

Future<Uint8List> _drawJob(List<Object?> job) async {
  IsolateRunner.reportProgress(0);
  final img.Image image = _oriented(
    _decode(job[0]! as Uint8List),
    job[2]! as int,
  );
  final List<List<List<double>>> strokes = _strokes(job[1]);
  _paintStrokes(image, strokes);
  final Uint8List bytes = _encoded(image);
  IsolateRunner.reportProgress(1);
  return bytes;
}

img.Image _decode(Uint8List bytes) {
  final img.Image? image = img.decodeImage(bytes);
  if (image == null) {
    throw const ValidationFailure(
      message: 'That photo could not be read as an image.',
      recoveryAction: 'Capture the photo again, then try again.',
    );
  }
  return image;
}

img.Image _oriented(img.Image source, int degrees) {
  final int quarter = ((degrees % 360) + 360) % 360;
  return switch (quarter) {
    90 => img.copyRotate(source, angle: 90),
    180 => img.copyRotate(source, angle: 180),
    270 => img.copyRotate(source, angle: 270),
    _ => source,
  };
}

img.Image _crop(
  img.Image source,
  double? left,
  double? top,
  double? width,
  double? height,
) {
  if (left == null || top == null || width == null || height == null) {
    return source;
  }
  if (width <= 0 || height <= 0) {
    return source;
  }
  final int x = (left * source.width).round().clamp(0, source.width - 1);
  final int y = (top * source.height).round().clamp(0, source.height - 1);
  final int w = (width * source.width).round().clamp(1, source.width - x);
  final int h = (height * source.height).round().clamp(1, source.height - y);
  return img.copyCrop(source, x: x, y: y, width: w, height: h);
}

void _paintText(img.Image image, String text) {
  const int pad = 8;
  final int fontHeight = img.arial24.lineHeight;
  final int textWidth = _textWidth(text).clamp(1, image.width);
  final int boxWidth = (textWidth + pad * 2).clamp(1, image.width);
  final int boxHeight = (fontHeight + pad).clamp(1, image.height);
  final int x = pad.clamp(0, image.width - 1);
  final int y = (image.height - boxHeight - pad).clamp(0, image.height - 1);
  img.fillRect(
    image,
    x1: x,
    y1: y,
    x2: (x + boxWidth - 1).clamp(0, image.width - 1),
    y2: (y + boxHeight - 1).clamp(0, image.height - 1),
    color: img.ColorRgb8(0, 0, 0),
  );
  img.drawString(
    image,
    text,
    font: img.arial24,
    x: (x + pad).clamp(0, image.width - 1),
    y: (y + 2).clamp(0, image.height - 1),
    color: img.ColorRgb8(255, 255, 255),
  );
}

int _textWidth(String text) {
  var width = 0;
  for (final int unit in text.codeUnits) {
    width += img.arial24.characterXAdvance(String.fromCharCode(unit));
  }
  return width;
}

void _paintStrokes(img.Image image, List<List<List<double>>> strokes) {
  final img.ColorRgb8 ink = img.ColorRgb8(220, 38, 38);
  for (final List<List<double>> stroke in strokes) {
    for (int index = 1; index < stroke.length; index++) {
      final List<double> from = stroke[index - 1];
      final List<double> to = stroke[index];
      if (from.length < 2 || to.length < 2) {
        continue;
      }
      img.drawLine(
        image,
        x1: (from[0] * image.width).round(),
        y1: (from[1] * image.height).round(),
        x2: (to[0] * image.width).round(),
        y2: (to[1] * image.height).round(),
        color: ink,
        thickness: 4,
      );
    }
  }
}

Uint8List _encoded(img.Image image) {
  return Uint8List.fromList(img.encodePng(image));
}

List<List<List<double>>> _strokes(Object? raw) {
  if (raw is! List) {
    return const <List<List<double>>>[];
  }
  return <List<List<double>>>[
    for (final Object? stroke in raw)
      if (stroke is List)
        <List<double>>[
          for (final Object? point in stroke)
            if (point is List && point.length >= 2)
              <double>[
                (point[0] as num).toDouble(),
                (point[1] as num).toDouble(),
              ],
        ],
  ];
}
