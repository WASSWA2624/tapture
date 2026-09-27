import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/result.dart';

/// Blurs detected faces on a copy. The original bytes are not written.
final class FaceBlur {
  /// Blurs each rectangle in [faces] on a copy of [original].
  ///
  /// [faceCount] is how many rectangles were blurred. The work runs off the
  /// UI isolate. [original] is left unchanged.
  static Future<FaceBlurCopy> apply(
    Uint8List original,
    List<FaceRect> faces,
  ) async {
    final Result<Uint8List> blurred = await runIsolate<List<Object>, Uint8List>(
      _blur,
      <Object>[original, _flat(faces)],
    );
    final Uint8List bytes = blurred.fold(
      (_) => Uint8List.fromList(original),
      (Uint8List value) => value,
    );
    return (bytes: bytes, faceCount: faces.length);
  }
}

/// A face rectangle in image pixels.
typedef FaceRect = ({int x, int y, int width, int height});

/// The derived photo and how many faces were blurred.
typedef FaceBlurCopy = ({Uint8List bytes, int faceCount});

List<int> _flat(List<FaceRect> faces) {
  return <int>[
    for (final FaceRect face in faces) ...<int>[
      face.x,
      face.y,
      face.width,
      face.height,
    ],
  ];
}

Uint8List _blur(List<Object> message) {
  final Uint8List original = message[0] as Uint8List;
  final List<int> flat = message[1] as List<int>;
  final img.Image? decoded = img.decodeImage(original);
  if (decoded == null || flat.isEmpty) {
    return Uint8List.fromList(original);
  }
  final img.Image copy = img.Image.from(decoded);
  for (var index = 0; index + 3 < flat.length; index += 4) {
    final int x = flat[index];
    final int y = flat[index + 1];
    final int width = flat[index + 2];
    final int height = flat[index + 3];
    var red = 0;
    var green = 0;
    var blue = 0;
    var count = 0;
    for (var py = y; py < y + height && py < copy.height; py++) {
      for (var px = x; px < x + width && px < copy.width; px++) {
        if (px < 0 || py < 0) {
          continue;
        }
        final img.Pixel pixel = copy.getPixel(px, py);
        red += pixel.r.toInt();
        green += pixel.g.toInt();
        blue += pixel.b.toInt();
        count++;
      }
    }
    if (count == 0) {
      continue;
    }
    final img.ColorRgb8 fill = img.ColorRgb8(
      red ~/ count,
      green ~/ count,
      blue ~/ count,
    );
    for (var py = y; py < y + height && py < copy.height; py++) {
      for (var px = x; px < x + width && px < copy.width; px++) {
        if (px < 0 || py < 0) {
          continue;
        }
        copy.setPixel(px, py, fill);
      }
    }
  }
  return img.encodePng(copy);
}
