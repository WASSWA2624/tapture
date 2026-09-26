import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/markup_stroke.dart';
import 'package:tapture/core/widgets/markup_text.dart';
import 'package:tapture/core/widgets/photo_markup.dart';

void main() {
  test('crop keeps the source bytes and writes a smaller image', () async {
    final Uint8List original = _png(width: 20, height: 10);
    final Uint8List snapshot = Uint8List.fromList(original);
    final Uint8List cropped = _ok(
      await PhotoMarkup.crop(original, const Rect.fromLTWH(0, 0, 0.5, 1)),
    );

    expect(original, snapshot);
    final img.Image? image = img.decodeImage(cropped);
    expect(image, isNotNull);
    expect(image!.width, lessThan(20));
  });

  test('rotation is applied before the crop', () async {
    final Uint8List original = _png(width: 20, height: 10);
    final Uint8List turned = _ok(
      await PhotoMarkup.crop(original, null, rotationDegrees: 90),
    );
    final img.Image? image = img.decodeImage(turned);
    expect(image!.width, 10);
    expect(image.height, 20);
  });

  test('cropping the left half keeps only the left colour', () async {
    final img.Image two = img.Image(width: 40, height: 20);
    img.fillRect(
      two,
      x1: 0,
      y1: 0,
      x2: 19,
      y2: 19,
      color: img.ColorRgb8(200, 0, 0),
    );
    img.fillRect(
      two,
      x1: 20,
      y1: 0,
      x2: 39,
      y2: 19,
      color: img.ColorRgb8(0, 0, 200),
    );
    final Uint8List cropped = _ok(
      await PhotoMarkup.crop(
        Uint8List.fromList(img.encodePng(two)),
        const Rect.fromLTWH(0, 0, 0.5, 1),
      ),
    );

    final img.Image image = img.decodeImage(cropped)!;
    expect(image.width, 20);
    for (int x = 0; x < image.width; x++) {
      final img.Pixel pixel = image.getPixel(x, image.height ~/ 2);
      expect(<num>[pixel.r, pixel.g, pixel.b], <num>[200, 0, 0]);
    }
  });

  test('a photo turned by its EXIF orientation is cropped upright', () async {
    final img.Image wide = img.Image(width: 20, height: 10)
      ..clear(img.ColorRgb8(20, 40, 60));
    wide.exif.imageIfd.orientation = 6;
    final Uint8List upright = _ok(
      await PhotoMarkup.crop(Uint8List.fromList(img.encodeJpg(wide)), null),
    );

    final img.Image image = img.decodeImage(upright)!;
    expect(image.width, 10);
    expect(image.height, 20);
  });

  test('a large blue stroke draws a blue line about 2 pixels wide', () async {
    final img.Image white = img.Image(width: 100, height: 100)
      ..clear(img.ColorRgb8(255, 255, 255));
    final Uint8List drawn = _ok(
      await PhotoMarkup.draw(
        Uint8List.fromList(img.encodePng(white)),
        const <MarkupStroke>[
          MarkupStroke(
            points: <Offset>[Offset(0.1, 0.5), Offset(0.9, 0.5)],
            ink: MarkupInk.blue,
            size: 2,
          ),
        ],
      ),
    );

    final img.Image image = img.decodeImage(drawn)!;
    final Color blue = MarkupInk.blue.color;
    final List<num> ink = <num>[
      (blue.r * 255).round(),
      (blue.g * 255).round(),
      (blue.b * 255).round(),
    ];
    for (final int x in <int>[20, 50, 80]) {
      int covered = 0;
      for (int y = 0; y < image.height; y++) {
        final img.Pixel pixel = image.getPixel(x, y);
        if (<num>[pixel.r, pixel.g, pixel.b].join(',') == ink.join(',')) {
          covered += 1;
          expect((y - 50).abs(), lessThanOrEqualTo(2));
        }
      }
      expect(covered, inInclusiveRange(1, 3), reason: 'column $x');
    }
    final img.Pixel corner = image.getPixel(5, 5);
    expect(<num>[corner.r, corner.g, corner.b], <num>[255, 255, 255]);
  });

  test('each stroke keeps its own ink', () async {
    final img.Image white = img.Image(width: 100, height: 100)
      ..clear(img.ColorRgb8(255, 255, 255));
    final Uint8List drawn = _ok(
      await PhotoMarkup.draw(
        Uint8List.fromList(img.encodePng(white)),
        const <MarkupStroke>[
          MarkupStroke(
            points: <Offset>[Offset(0.1, 0.25), Offset(0.9, 0.25)],
            ink: MarkupInk.red,
            size: 2,
          ),
          MarkupStroke(
            points: <Offset>[Offset(0.1, 0.75), Offset(0.9, 0.75)],
            ink: MarkupInk.green,
            size: 2,
          ),
        ],
      ),
    );

    final img.Image image = img.decodeImage(drawn)!;
    expect(_inkNear(image, 50, 25), _inkRgb(MarkupInk.red));
    expect(_inkNear(image, 50, 75), _inkRgb(MarkupInk.green));
  });

  test('large white text lands on its centre, not the old corner', () async {
    final img.Image black = img.Image(width: 200, height: 100)
      ..clear(img.ColorRgb8(0, 0, 0));
    final Uint8List typed = _ok(
      await PhotoMarkup.typeOn(
        Uint8List.fromList(img.encodePng(black)),
        const MarkupText(
          text: 'HELLO',
          ink: MarkupInk.white,
          size: 2,
          centre: Offset(0.5, 0.4),
          backing: false,
        ),
      ),
    );

    final img.Image image = img.decodeImage(typed)!;
    expect(image.width, 200);
    // Line height is 11% of 100 px, centred on (100, 40).
    expect(_brightIn(image, left: 60, top: 32, right: 140, bottom: 48), isTrue);
    expect(_brightIn(image, left: 0, top: 60, right: 80, bottom: 100), isFalse);
    expect(_brightIn(image, left: 0, top: 0, right: 200, bottom: 28), isFalse);
  });

  test('two lines stack, and the backing is dark behind them', () async {
    final img.Image white = img.Image(width: 200, height: 200)
      ..clear(img.ColorRgb8(255, 255, 255));
    final Uint8List typed = _ok(
      await PhotoMarkup.typeOn(
        Uint8List.fromList(img.encodePng(white)),
        const MarkupText(
          text: 'AB\nCD',
          ink: MarkupInk.yellow,
          size: 1,
          centre: Offset(0.5, 0.5),
        ),
      ),
    );

    final img.Image image = img.decodeImage(typed)!;
    // Two 14 px lines and 4 px of backing each side make a 36 px block
    // centred on 100.
    final img.Pixel backing = image.getPixel(100, 83);
    expect(backing.r, lessThan(120));
    expect(_rgb(image.getPixel(100, 60)), <num>[255, 255, 255]);
    expect(_rgb(image.getPixel(100, 140)), <num>[255, 255, 255]);
  });

  test('text with no words is refused', () async {
    final Result<Uint8List> typed = await PhotoMarkup.typeOn(
      _png(width: 20, height: 10),
      const MarkupText(text: '  \n ', ink: MarkupInk.red, size: 1),
    );
    expect(
      typed.fold((Failure failure) => failure.message, (Uint8List _) => 'ok'),
      'Type the words to place on this photo.',
    );
  });

  test('text and drawing write a new image', () async {
    final Uint8List original = _png(width: 80, height: 40);
    final Uint8List typed = _ok(
      await PhotoMarkup.typeOn(
        original,
        const MarkupText(text: 'Ward 2', ink: MarkupInk.white, size: 1),
      ),
    );
    final Uint8List drawn = _ok(
      await PhotoMarkup.draw(original, const <MarkupStroke>[
        MarkupStroke(
          points: <Offset>[Offset(0.1, 0.1), Offset(0.8, 0.8)],
          ink: MarkupInk.red,
          size: 1,
        ),
      ]),
    );
    expect(typed, isNot(original));
    expect(drawn, isNot(original));
  });
}

Uint8List _png({required int width, required int height}) {
  final img.Image image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(20, 40, 60));
  return Uint8List.fromList(img.encodePng(image));
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

List<num> _rgb(img.Pixel pixel) => <num>[pixel.r, pixel.g, pixel.b];

List<num> _inkRgb(MarkupInk ink) {
  return <num>[
    (ink.color.r * 255).round(),
    (ink.color.g * 255).round(),
    (ink.color.b * 255).round(),
  ];
}

/// The first colour that is not white within two pixels above or below
/// ([x], [y]), so a stroke's rounding does not decide the test.
List<num> _inkNear(img.Image image, int x, int y) {
  for (int row = y - 2; row <= y + 2; row++) {
    final List<num> rgb = _rgb(image.getPixel(x, row));
    if (rgb.join(',') != '255,255,255') {
      return rgb;
    }
  }
  return const <num>[255, 255, 255];
}

/// Whether any pixel inside the box is bright.
bool _brightIn(
  img.Image image, {
  required int left,
  required int top,
  required int right,
  required int bottom,
}) {
  for (int y = top; y < bottom; y++) {
    for (int x = left; x < right; x++) {
      if (image.getPixel(x, y).r > 160) {
        return true;
      }
    }
  }
  return false;
}
