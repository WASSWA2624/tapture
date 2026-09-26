import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/markup_stroke.dart';
import 'package:tapture/core/widgets/markup_text.dart';

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

  /// Paints [text] on a copy of [bytes] in its ink and size, centred where
  /// it was placed, over a dark backing when it has one.
  static Future<Result<Uint8List>> typeOn(
    Uint8List bytes,
    MarkupText text, {
    int rotationDegrees = 0,
  }) async {
    // Refused here, so the reason reaches the screen rather than an
    // isolate error.
    if (text.text.trim().isEmpty) {
      return const FailureResult<Uint8List>(_noWords);
    }
    return runIsolate(_typeJob, <Object?>[
      bytes,
      text.text,
      rotationDegrees,
      text.ink.color.toARGB32(),
      text.lineFraction,
      text.centre.dx,
      text.centre.dy,
      text.backing,
    ]);
  }

  /// Paints [strokes] onto a copy, each in its own ink and at its own width
  /// relative to the photo's short edge, where they were drawn on screen.
  static Future<Result<Uint8List>> draw(
    Uint8List bytes,
    List<MarkupStroke> strokes, {
    int rotationDegrees = 0,
  }) {
    // Plain values cross into the isolate on every platform.
    final List<Object?> plain = <Object?>[
      for (final MarkupStroke stroke in strokes)
        <Object?>[
          stroke.ink.color.toARGB32(),
          stroke.widthFraction,
          <double>[
            for (final Offset point in stroke.points) ...<double>[
              point.dx,
              point.dy,
            ],
          ],
        ],
    ];
    return runIsolate(_drawJob, <Object?>[bytes, plain, rotationDegrees]);
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

const ValidationFailure _noWords = ValidationFailure(
  message: 'Type the words to place on this photo.',
  recoveryAction: 'Enter text, then save the photo.',
);

Future<Uint8List> _typeJob(List<Object?> job) async {
  IsolateRunner.reportProgress(0);
  final img.Image image = _oriented(
    _decode(job[0]! as Uint8List),
    job[2]! as int,
  );
  final String text = (job[1]! as String).trim();
  if (text.isEmpty) {
    throw _noWords;
  }
  _paintText(
    image,
    text,
    argb: job[3]! as int,
    lineFraction: (job[4]! as num).toDouble(),
    centre: Offset((job[5]! as num).toDouble(), (job[6]! as num).toDouble()),
    backing: job[7]! as bool,
  );
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
  _paintStrokes(image, _strokes(job[1]));
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
  // The screens show the photo upright, as its EXIF orientation says, so
  // fractions measured there apply to the upright pixels.
  if (image.exif.imageIfd.hasOrientation &&
      image.exif.imageIfd.orientation != 1) {
    return img.bakeOrientation(image);
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

/// Draws each line with the bitmap Arial 48 into its own layer, scales it
/// to the line height, and composites the lines centred on [centre], over a
/// translucent black backing first when [backing] is set (D4). The block
/// stays inside the photo, as it does on screen.
void _paintText(
  img.Image image,
  String text, {
  required int argb,
  required double lineFraction,
  required Offset centre,
  required bool backing,
}) {
  final img.BitmapFont font = img.arial48;
  final img.ColorRgba8 ink = img.ColorRgba8(
    (argb >> 16) & 0xFF,
    (argb >> 8) & 0xFF,
    argb & 0xFF,
    0xFF,
  );
  final int lineHeight = (lineFraction * image.height).round().clamp(
    1,
    image.height,
  );
  final List<img.Image> layers = <img.Image>[
    for (final String line in text.split('\n'))
      _lineLayer(line.trimRight(), font, ink, lineHeight),
  ];
  int blockWidth = 1;
  for (final img.Image layer in layers) {
    if (layer.width > blockWidth) {
      blockWidth = layer.width;
    }
  }
  final int pad = backing
      ? (lineHeight * AppConstants.markup.backingPad).round()
      : 0;
  final int boxWidth = (blockWidth + pad * 2).clamp(1, image.width);
  final int boxHeight = (lineHeight * layers.length + pad * 2).clamp(
    1,
    image.height,
  );
  final int left = (centre.dx * image.width - boxWidth / 2).round().clamp(
    0,
    image.width - boxWidth,
  );
  final int top = (centre.dy * image.height - boxHeight / 2).round().clamp(
    0,
    image.height - boxHeight,
  );
  if (backing) {
    img.fillRect(
      image,
      x1: left,
      y1: top,
      x2: left + boxWidth - 1,
      y2: top + boxHeight - 1,
      color: img.ColorRgba8(
        0,
        0,
        0,
        (AppConstants.markup.backingAlpha * 0xFF).round(),
      ),
    );
  }
  for (int index = 0; index < layers.length; index++) {
    final img.Image layer = layers[index];
    img.compositeImage(
      image,
      layer,
      dstX: left + pad + (blockWidth - layer.width) ~/ 2,
      dstY: top + pad + index * lineHeight,
    );
  }
}

/// One line drawn at the font's own size, then scaled to [lineHeight].
img.Image _lineLayer(
  String line,
  img.BitmapFont font,
  img.Color ink,
  int lineHeight,
) {
  final int width = _textWidth(line, font);
  if (width <= 0) {
    return img.Image(width: 1, height: lineHeight, numChannels: 4);
  }
  final img.Image layer = img.Image(
    width: width,
    height: font.lineHeight,
    numChannels: 4,
  );
  img.drawString(layer, line, font: font, x: 0, y: 0, color: ink);
  final double scale = lineHeight / font.lineHeight;
  return img.copyResize(
    layer,
    width: (width * scale).round().clamp(1, 1 << 16),
    height: lineHeight,
    interpolation: img.Interpolation.linear,
  );
}

/// The width [font] draws [text] at. Characters it has no glyph for are
/// skipped, as the font skips them.
int _textWidth(String text, img.BitmapFont font) {
  var width = 0;
  for (final int unit in text.codeUnits) {
    width += font.characters[unit]?.xAdvance ?? 0;
  }
  return width;
}

void _paintStrokes(img.Image image, List<_Stroke> strokes) {
  final int shortEdge = image.width < image.height ? image.width : image.height;
  for (final _Stroke stroke in strokes) {
    final int argb = stroke.argb;
    final img.ColorRgb8 ink = img.ColorRgb8(
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
    );
    final int width = (stroke.widthFraction * shortEdge).round().clamp(
      1,
      shortEdge,
    );
    final List<double> xy = stroke.points;
    for (int index = 2; index + 1 < xy.length; index += 2) {
      img.drawLine(
        image,
        x1: (xy[index - 2] * image.width).round(),
        y1: (xy[index - 1] * image.height).round(),
        x2: (xy[index] * image.width).round(),
        y2: (xy[index + 1] * image.height).round(),
        color: ink,
        thickness: width,
      );
    }
    // Round joins, as the on-screen pen draws them, once a joint would
    // otherwise show a notch.
    if (width >= _roundJoinWidth) {
      for (int index = 0; index + 1 < xy.length; index += 2) {
        img.fillCircle(
          image,
          x: (xy[index] * image.width).round(),
          y: (xy[index + 1] * image.height).round(),
          radius: width ~/ 2,
          color: ink,
        );
      }
    }
  }
}

/// The stroke width, in image pixels, from which joints are rounded.
const int _roundJoinWidth = 4;

/// A stroke as it crosses into the isolate.
typedef _Stroke = ({int argb, double widthFraction, List<double> points});

Uint8List _encoded(img.Image image) {
  return Uint8List.fromList(img.encodePng(image));
}

List<_Stroke> _strokes(Object? raw) {
  if (raw is! List) {
    return const <_Stroke>[];
  }
  return <_Stroke>[
    for (final Object? stroke in raw)
      if (stroke is List &&
          stroke.length == 3 &&
          stroke[0] is int &&
          stroke[1] is num &&
          stroke[2] is List)
        (
          argb: stroke[0] as int,
          widthFraction: (stroke[1] as num).toDouble(),
          points: <double>[
            for (final Object? value in stroke[2] as List)
              if (value is num) value.toDouble(),
          ],
        ),
  ];
}
