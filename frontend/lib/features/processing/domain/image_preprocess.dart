import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tapture/core/constants/app_constants.dart';

/// Derived pixels for extraction. The original bytes are never rewritten.
///
/// Resize, orientation, deskew, contrast and a document crop, in that order.
final class ImagePreprocess {
  /// Builds a derived JPEG. [longEdge] defaults to the upload long edge.
  static Uint8List prepare(Uint8List original, {int? longEdge}) {
    final img.Image? decoded = img.decodeImage(original);
    if (decoded == null) {
      return Uint8List(0);
    }
    img.Image current = img.bakeOrientation(decoded);
    current = _resize(current, longEdge ?? AppConstants.images.longEdge);
    current = _deskew(current);
    current = _contrast(current);
    current = _cropToDocument(current);
    return Uint8List.fromList(
      img.encodeJpg(current, quality: AppConstants.images.quality),
    );
  }
}

img.Image _resize(img.Image source, int longEdge) {
  final int edge = source.width > source.height ? source.width : source.height;
  if (edge <= longEdge || longEdge <= 0) {
    return source;
  }
  final double scale = longEdge / edge;
  return img.copyResize(
    source,
    width: (source.width * scale).round(),
    height: (source.height * scale).round(),
    interpolation: img.Interpolation.linear,
  );
}

img.Image _contrast(img.Image source) {
  return img.adjustColor(source, contrast: 1.25);
}

img.Image _cropToDocument(img.Image source) {
  final int width = source.width;
  final int height = source.height;
  var top = 0;
  var left = 0;
  var right = width - 1;
  var bottom = height - 1;
  var found = false;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (_ink(source.getPixel(x, y))) {
        if (!found || y < top) {
          top = y;
        }
        if (!found || y > bottom) {
          bottom = y;
        }
        if (!found || x < left) {
          left = x;
        }
        if (!found || x > right) {
          right = x;
        }
        found = true;
      }
    }
  }
  if (!found) {
    return source;
  }
  final int cropWidth = right - left + 1;
  final int cropHeight = bottom - top + 1;
  if (cropWidth >= width && cropHeight >= height) {
    return source;
  }
  return img.copyCrop(
    source,
    x: left,
    y: top,
    width: cropWidth,
    height: cropHeight,
  );
}

img.Image _deskew(img.Image source) {
  if (source.width < 16 || source.height < 16) {
    return source;
  }
  final int upright = _projection(source);
  var best = source;
  var bestScore = upright;
  final int margin = upright ~/ 5 + 1;
  for (final double degrees in const <double>[-2, -1, 1, 2]) {
    final img.Image rotated = img.copyRotate(source, angle: degrees);
    final int score = _projection(rotated);
    if (score > bestScore + margin) {
      bestScore = score;
      best = rotated;
    }
  }
  return best;
}

int _projection(img.Image source) {
  var score = 0;
  final int stepX = source.width > 80 ? source.width ~/ 80 : 1;
  final int stepY = source.height > 80 ? source.height ~/ 80 : 1;
  for (var y = 0; y < source.height; y += stepY) {
    var run = 0;
    for (var x = 0; x < source.width; x += stepX) {
      if (_ink(source.getPixel(x, y))) {
        run++;
      } else if (run > 0) {
        score += run * run;
        run = 0;
      }
    }
    score += run * run;
  }
  return score;
}

bool _ink(img.Pixel pixel) {
  final num luma = img.getLuminance(pixel);
  return luma < 180;
}
