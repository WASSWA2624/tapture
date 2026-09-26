import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

/// Derived pixels for extraction. The original bytes are never rewritten.
///
/// Resize, orientation, deskew, contrast and a document crop, in that order.
final class ImagePreprocess {
  /// Builds a derived JPEG. [longEdge] defaults to the upload long edge.
  static Uint8List prepare(Uint8List original, {int? longEdge}) {
    return _prepare(original, longEdge ?? AppConstants.images.longEdge, _quiet);
  }

  /// Builds the derived bytes away from the UI isolate.
  ///
  /// [onProgress] hears 0 to 1 as each step finishes. [cancel] tears the
  /// isolate down mid-step and completes with a cancelled failure.
  static Future<Result<Uint8List>> prepareOffThread(
    Uint8List original, {
    int? longEdge,
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) {
    return runIsolate(
      _prepareJob,
      <Object?>[original, longEdge ?? AppConstants.images.longEdge],
      cancel: cancel,
      onProgress: onProgress,
    );
  }
}

/// The steps after decoding, each reported as it finishes.
const int _steps = 6;

void _quiet(double fraction) {}

Uint8List _prepare(
  Uint8List original,
  int longEdge,
  void Function(double) report,
) {
  final img.Image? decoded = _decode(original);
  if (decoded == null) {
    return Uint8List(0);
  }
  var done = 0;
  void step() => report(++done / _steps);
  img.Image current = img.bakeOrientation(decoded);
  step();
  current = _resize(current, longEdge);
  step();
  current = _deskew(current);
  step();
  current = _opaqueOnWhite(current);
  current = _contrast(current);
  step();
  current = _cropToDocument(current);
  step();
  final Uint8List encoded = Uint8List.fromList(
    img.encodeJpg(current, quality: AppConstants.images.quality),
  );
  step();
  return encoded;
}

/// The decoded photo, or null when the bytes are not an image the decoder
/// can read; some broken files throw rather than return null.
img.Image? _decode(Uint8List bytes) {
  try {
    return img.decodeImage(bytes);
  } on Object {
    return null;
  }
}

img.Image _opaqueOnWhite(img.Image source) {
  if (!source.hasAlpha) {
    return source;
  }
  final img.Image background = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(background, color: img.ColorRgb8(255, 255, 255));
  return img.compositeImage(background, source);
}

Future<Uint8List> _prepareJob(List<Object?> job) async {
  IsolateRunner.reportProgress(0);
  return _prepare(
    job[0]! as Uint8List,
    job[1]! as int,
    IsolateRunner.reportProgress,
  );
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
  return img.adjustColor(
    source,
    contrast: AppConstants.processing.preprocessContrast,
  );
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
  final int minEdge = AppConstants.processing.deskewMinEdge;
  if (source.width < minEdge || source.height < minEdge) {
    return source;
  }
  final int upright = _projection(source);
  var best = source;
  var bestScore = upright;
  // Small compression artefacts can otherwise look like a better baseline
  // and rotate an already-upright plate. Require a decisive improvement.
  final int margin = upright ~/ AppConstants.processing.deskewMarginDivisor + 1;
  final img.Image rotatable = source.hasAlpha
      ? source
      : source.convert(numChannels: 4);
  for (final double degrees in AppConstants.processing.deskewAnglesDegrees) {
    final img.Image rotated = img.copyRotate(rotatable, angle: degrees);
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
  final int samples = AppConstants.processing.projectionSamples;
  final int stepX = source.width > samples ? source.width ~/ samples : 1;
  final int stepY = source.height > samples ? source.height ~/ samples : 1;
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
  if (pixel.length >= 4 && pixel.aNormalized < 0.5) {
    return false;
  }
  final num luma = img.getLuminance(pixel);
  return luma < AppConstants.processing.inkLumaThreshold;
}
