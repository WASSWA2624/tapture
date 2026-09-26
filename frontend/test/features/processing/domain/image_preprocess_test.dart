import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/domain/image_preprocess.dart';

void main() {
  Uint8List photo({int width = 1200, int height = 800}) {
    final img.Image image = img.Image(width: width, height: height)
      ..clear(img.ColorRgb8(235, 235, 235));
    img.fillRect(
      image,
      x1: width ~/ 4,
      y1: height ~/ 3,
      x2: width * 3 ~/ 4,
      y2: height ~/ 2,
      color: img.ColorRgb8(20, 20, 20),
    );
    return Uint8List.fromList(img.encodeJpg(image));
  }

  test('the original is byte-identical after preprocessing', () {
    final Uint8List original = photo();
    final Digest before = sha256.convert(original);
    final Uint8List derived = ImagePreprocess.prepare(original, longEdge: 600);
    expect(sha256.convert(original), before);
    expect(derived, isNot(original));
  });

  test('the derived copy is a decodable JPEG within the long edge', () {
    final Uint8List derived = ImagePreprocess.prepare(photo(), longEdge: 600);
    final img.Image? decoded = img.decodeJpg(derived);
    expect(decoded, isNotNull);
    expect(decoded!.width <= 600 && decoded.height <= 600, isTrue);
  });

  test('bytes that are not an image yield nothing', () {
    expect(
      ImagePreprocess.prepare(Uint8List.fromList(<int>[1, 2, 3])),
      isEmpty,
    );
  });

  test(
    'the off-thread path reports progress and leaves the original',
    () async {
      final Uint8List original = photo(width: 400, height: 300);
      final Uint8List copy = Uint8List.fromList(original);
      final List<double> progress = <double>[];
      final Result<Uint8List> result = await ImagePreprocess.prepareOffThread(
        original,
        longEdge: 300,
        onProgress: progress.add,
      );
      expect(result, isA<Success<Uint8List>>());
      expect(original, copy);
      expect(progress, isNotEmpty);
    },
  );
}
