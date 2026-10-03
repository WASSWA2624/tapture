import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/result.dart';

/// Scores a durably written photo for blur, darkness, overexposure and small
/// text. Advisory only: a finding never blocks a save and never discards the
/// photo (FE-SIMP-08).
abstract final class ImageQuality {
  /// The long edge the photo is reduced to before scoring, so a 12 MP shot
  /// costs no more than a thumbnail.
  static const int sampleEdge = 256;

  /// Mean luminance below which a photo reads as dark.
  static const double darkMean = 50;

  /// Mean luminance above which a photo reads as overexposed.
  static const double brightMean = 205;

  /// Laplacian variance below which a photo reads as blurred.
  static const double blurVariance = 60;

  /// Share of sampled pixels on a strong edge above which the detail is finer
  /// than a reader can make out: small text.
  static const double smallTextEdgeShare = 0.3;

  /// Laplacian magnitude that counts as a strong edge.
  static const int edgeStrength = 48;

  /// The strongest advisory finding for encoded [bytes]. Bytes the decoder
  /// cannot read raise no advisory: the file itself is already stored.
  static ImageQualityFinding score(Uint8List bytes) {
    final img.Image? decoded = _decode(bytes);
    return decoded == null ? ImageQualityFinding.clean : scoreImage(decoded);
  }

  /// [score] on the isolate runner, after the photo is durably written
  /// (FE-PERF-02). A failed run raises no advisory.
  static Future<ImageQualityFinding> scoreOffThread(Uint8List bytes) async {
    final Result<ImageQualityFinding> scored = await runIsolate(score, bytes);
    return switch (scored) {
      Success<ImageQualityFinding>(:final ImageQualityFinding value) => value,
      FailureResult<ImageQualityFinding>() => ImageQualityFinding.clean,
    };
  }

  /// The strongest advisory finding for decoded [image].
  static ImageQualityFinding scoreImage(img.Image image) {
    final _Luma luma = _Luma.of(image);
    if (luma.width < 3 || luma.height < 3) {
      return ImageQualityFinding.clean;
    }
    final double mean = luma.mean;
    if (mean < darkMean) {
      return ImageQualityFinding.dark;
    }
    if (mean > brightMean) {
      return ImageQualityFinding.overexposed;
    }
    final ({double variance, double edgeShare}) edges = luma.laplacian();
    if (edges.variance < blurVariance) {
      return ImageQualityFinding.blurry;
    }
    if (edges.edgeShare > smallTextEdgeShare) {
      return ImageQualityFinding.smallText;
    }
    return ImageQualityFinding.clean;
  }

  /// Catalogue copy for an advisory, or null when clean.
  static String? message(ImageQualityFinding finding) {
    return switch (finding) {
      ImageQualityFinding.clean => null,
      ImageQualityFinding.blurry => DomainCopy.captureQualityBlur,
      ImageQualityFinding.dark => DomainCopy.captureQualityDark,
      ImageQualityFinding.overexposed => DomainCopy.captureQualityBright,
      ImageQualityFinding.smallText => DomainCopy.captureQualitySmallText,
    };
  }
}

/// Advisory quality findings after a photo is durably written.
enum ImageQualityFinding {
  /// Looks sharp and exposed.
  clean,

  /// Likely motion or focus blur.
  blurry,

  /// Mean luminance too low.
  dark,

  /// Mean luminance too high.
  overexposed,

  /// Detail finer than a reader can make out: small text at risk.
  smallText,
}

/// The decoded photo, upright, or null when the bytes are not an image the
/// decoder can read; some broken files throw rather than return null.
img.Image? _decode(Uint8List bytes) {
  try {
    final img.Image? decoded = img.decodeImage(bytes);
    return decoded == null ? null : img.bakeOrientation(decoded);
  } on Object {
    return null;
  }
}

/// Luminance of a photo reduced to [ImageQuality.sampleEdge] on its long
/// edge, one byte per pixel.
final class _Luma {
  _Luma._(this.width, this.height, this.values);

  factory _Luma.of(img.Image image) {
    final int edge = max(image.width, image.height);
    final img.Image sample = edge <= ImageQuality.sampleEdge
        ? image
        : img.copyResize(
            image,
            width: max(1, image.width * ImageQuality.sampleEdge ~/ edge),
            height: max(1, image.height * ImageQuality.sampleEdge ~/ edge),
            interpolation: img.Interpolation.average,
          );
    final Uint8List values = Uint8List(sample.width * sample.height);
    var index = 0;
    for (var y = 0; y < sample.height; y++) {
      for (var x = 0; x < sample.width; x++) {
        final num luma = img.getLuminanceNormalized(sample.getPixel(x, y));
        values[index++] = (luma * 255).round().clamp(0, 255);
      }
    }
    return _Luma._(sample.width, sample.height, values);
  }

  final int width;
  final int height;
  final Uint8List values;

  double get mean {
    var sum = 0;
    for (final int value in values) {
      sum += value;
    }
    return sum / values.length;
  }

  /// Variance of the four-neighbour Laplacian, and the share of interior
  /// pixels whose Laplacian marks a strong edge.
  ({double variance, double edgeShare}) laplacian() {
    var count = 0;
    var sum = 0.0;
    var squares = 0.0;
    var strong = 0;
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final int at = y * width + x;
        final int response =
            4 * values[at] -
            values[at - 1] -
            values[at + 1] -
            values[at - width] -
            values[at + width];
        sum += response;
        squares += response * response;
        count++;
        if (response.abs() >= ImageQuality.edgeStrength) {
          strong++;
        }
      }
    }
    final double average = sum / count;
    return (
      variance: squares / count - average * average,
      edgeShare: strong / count,
    );
  }
}
