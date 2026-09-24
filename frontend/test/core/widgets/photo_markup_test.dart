import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
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

  test('text and drawing write a new image', () async {
    final Uint8List original = _png(width: 80, height: 40);
    final Uint8List typed = _ok(await PhotoMarkup.typeOn(original, 'Ward 2'));
    final Uint8List drawn = _ok(
      await PhotoMarkup.draw(original, <List<List<double>>>[
        <List<double>>[
          <double>[0.1, 0.1],
          <double>[0.8, 0.8],
        ],
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
