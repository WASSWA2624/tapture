import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/hash/perceptual_hash.dart';

void main() {
  /// A plate-like photo: a light field with dark text bars and a frame.
  img.Image plate() {
    final img.Image image = img.Image(width: 640, height: 480)
      ..clear(img.ColorRgb8(225, 225, 220));
    for (var row = 0; row < 5; row++) {
      img.fillRect(
        image,
        x1: 60 + row * 20,
        y1: 60 + row * 70,
        x2: 580 - row * 40,
        y2: 95 + row * 70,
        color: img.ColorRgb8(30, 30, 35),
      );
    }
    img.drawRect(
      image,
      x1: 10,
      y1: 10,
      x2: 629,
      y2: 469,
      color: img.ColorRgb8(0, 0, 0),
      thickness: 6,
    );
    return image;
  }

  /// An unrelated photo: a dark left half and a light right half.
  img.Image other() {
    final img.Image image = img.Image(width: 640, height: 480)
      ..clear(img.ColorRgb8(240, 240, 240));
    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: 319,
      y2: 479,
      color: img.ColorRgb8(15, 15, 15),
    );
    return image;
  }

  final String original = PerceptualHash.ofBytes(
    Uint8List.fromList(img.encodePng(plate())),
  );

  test('a hash is sixteen hex characters', () {
    expect(original, matches(RegExp(r'^[0-9a-f]{16}$')));
  });

  test('a resized copy matches', () {
    final img.Image half = img.copyResize(plate(), width: 320);
    final String resized = PerceptualHash.ofBytes(
      Uint8List.fromList(img.encodeJpg(half)),
    );
    expect(PerceptualHash.matches(original, resized), isTrue);
  });

  test('a recompressed copy matches', () {
    final String recompressed = PerceptualHash.ofBytes(
      Uint8List.fromList(img.encodeJpg(plate(), quality: 35)),
    );
    expect(PerceptualHash.matches(original, recompressed), isTrue);
    expect(
      PerceptualHash.distance(original, recompressed),
      lessThanOrEqualTo(AppConstants.processing.perceptualHashDistance),
    );
  });

  test('an unrelated photo does not match', () {
    final String unrelated = PerceptualHash.ofBytes(
      Uint8List.fromList(img.encodePng(other())),
    );
    expect(PerceptualHash.matches(original, unrelated), isFalse);
  });

  test('distance is symmetric, and empty or malformed hashes miss', () {
    expect(PerceptualHash.distance('00ff', 'ff00'), 16);
    expect(PerceptualHash.distance('ff00', '00ff'), 16);
    expect(PerceptualHash.distance(original, original), 0);
    expect(PerceptualHash.matches('', original), isFalse);
    expect(PerceptualHash.matches('zz', 'zz'), isFalse);
    expect(PerceptualHash.matches('abc', 'abcd'), isFalse);
  });

  test('nearest picks the closest stored hash inside the threshold', () {
    final String recompressed = PerceptualHash.ofBytes(
      Uint8List.fromList(img.encodeJpg(plate(), quality: 50)),
    );
    final String unrelated = PerceptualHash.ofBytes(
      Uint8List.fromList(img.encodePng(other())),
    );
    expect(
      PerceptualHash.nearest(recompressed, <String, String>{
        'plate': original,
        'other': unrelated,
      }),
      'plate',
    );
    expect(
      PerceptualHash.nearest(unrelated, <String, String>{'plate': original}),
      isNull,
    );
  });

  test('bytes that are not an image hash to nothing', () {
    expect(PerceptualHash.ofBytes(Uint8List.fromList(<int>[1, 2, 3])), '');
  });

  test('hashing runs off the UI thread', () async {
    final Result<String> result = await PerceptualHash.ofBytesOffThread(
      Uint8List.fromList(img.encodePng(plate())),
    );
    expect(result, isA<Success<String>>());
    expect((result as Success<String>).value, original);
  });
}
