import 'dart:math';
import 'dart:typed_data';

import 'package:tapture/core/copy/copy.dart';

/// Advisory quality findings after a photo is durably written. Never blocks
/// a save (FE-SIMP-08).
enum ImageQualityFinding {
  /// Looks sharp and exposed.
  clean,

  /// Likely motion or focus blur.
  blurry,

  /// Mean luminance too low.
  dark,

  /// Mean luminance too high.
  overexposed,

  /// High-frequency content suggests small text at risk.
  smallText,
}

/// Scores JPEG/PNG-ish bytes with cheap heuristics — no decode plugin.
abstract final class ImageQuality {
  /// Returns the strongest advisory finding for [bytes].
  static ImageQualityFinding score(Uint8List bytes) {
    if (bytes.isEmpty) {
      return ImageQualityFinding.dark;
    }
    var sum = 0;
    var samples = 0;
    var edge = 0;
    final int step = max(1, bytes.length ~/ 2048);
    for (var i = 0; i < bytes.length; i += step) {
      final int v = bytes[i];
      sum += v;
      samples++;
      if (i + step < bytes.length) {
        edge += (bytes[i] - bytes[i + step]).abs();
      }
    }
    if (samples == 0) {
      return ImageQualityFinding.dark;
    }
    final double mean = sum / samples;
    final double edgeMean = edge / max(1, samples - 1);
    if (mean < 40) {
      return ImageQualityFinding.dark;
    }
    if (mean > 220) {
      return ImageQualityFinding.overexposed;
    }
    if (edgeMean < 8) {
      return ImageQualityFinding.blurry;
    }
    if (edgeMean > 90 && mean > 80 && mean < 180) {
      return ImageQualityFinding.smallText;
    }
    return ImageQualityFinding.clean;
  }

  /// Catalogue copy for an advisory, or null when clean.
  static String? message(ImageQualityFinding finding) {
    return switch (finding) {
      ImageQualityFinding.clean => null,
      ImageQualityFinding.blurry => Copy.captureQualityBlur,
      ImageQualityFinding.dark => Copy.captureQualityDark,
      ImageQualityFinding.overexposed => Copy.captureQualityBright,
      ImageQualityFinding.smallText => Copy.captureQualitySmallText,
    };
  }
}
