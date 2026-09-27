import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/export/face_blur.dart';

void main() {
  test(
    'the original is unchanged and the copy reports the face count',
    () async {
      final img.Image source = img.Image(width: 4, height: 4);
      img.fill(source, color: img.ColorRgb8(10, 20, 30));
      source.setPixel(1, 1, img.ColorRgb8(200, 10, 10));
      final Uint8List original = img.encodePng(source);
      final Digest before = sha256.convert(original);
    final FaceBlurCopy copy = await FaceBlur.apply(original, const <FaceRect>[
      (x: 0, y: 0, width: 2, height: 2),
    ]);
      expect(sha256.convert(original), before);
      expect(copy.faceCount, 1);
      expect(copy.bytes, isNot(equals(original)));
    },
  );
}
