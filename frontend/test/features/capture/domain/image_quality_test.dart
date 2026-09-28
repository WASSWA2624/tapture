import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/capture/domain/image_quality.dart';

/// Task 012 budget: shutter to ready is under 400 ms, and scoring runs
/// after the write inside that same breath (FE-PERF-01, FE-TEST-09).
const Duration _shutterBudget = Duration(milliseconds: 400);

/// [length] bytes cycling through [values].
Uint8List _cycle(List<int> values, {int length = 512}) {
  return Uint8List.fromList(<int>[
    for (var i = 0; i < length; i++) values[i % values.length],
  ]);
}

void main() {
  group('score', () {
    test('a dark frame is reported dark', () {
      expect(ImageQuality.score(_cycle(<int>[10])), ImageQualityFinding.dark);
    });

    test('a washed-out frame is reported overexposed', () {
      expect(
        ImageQuality.score(_cycle(<int>[240])),
        ImageQualityFinding.overexposed,
      );
    });

    test('a flat mid-tone frame is reported blurry', () {
      expect(
        ImageQuality.score(_cycle(<int>[120])),
        ImageQualityFinding.blurry,
      );
    });

    test('a busy high-contrast mid-tone frame is flagged as small text', () {
      expect(
        ImageQuality.score(_cycle(<int>[30, 220])),
        ImageQualityFinding.smallText,
      );
    });

    test('a well-lit frame with moderate detail is clean', () {
      expect(
        ImageQuality.score(_cycle(<int>[100, 140])),
        ImageQualityFinding.clean,
      );
    });

    test('an empty file is reported dark rather than clean', () {
      expect(ImageQuality.score(Uint8List(0)), ImageQualityFinding.dark);
    });

    test('exposure is judged before sharpness', () {
      // Flat and dark: dark is the finding a retake would fix first.
      expect(ImageQuality.score(_cycle(<int>[5])), ImageQualityFinding.dark);
      expect(
        ImageQuality.score(_cycle(<int>[250])),
        ImageQualityFinding.overexposed,
      );
    });

    test('a one-megabyte frame is sampled, scored clean and stays inside '
        'the shutter budget', () {
      final Uint8List frame = _cycle(<int>[100, 120, 140], length: 1 << 20);
      final Stopwatch clock = Stopwatch()..start();

      final ImageQualityFinding finding = ImageQuality.score(frame);
      clock.stop();

      expect(finding, ImageQualityFinding.clean);
      expect(clock.elapsed, lessThan(_shutterBudget));
    });
  });

  group('message', () {
    test('a clean frame has no advisory', () {
      expect(ImageQuality.message(ImageQualityFinding.clean), isNull);
    });

    test('every other finding names its advisory from the catalogue', () {
      expect(
        ImageQuality.message(ImageQualityFinding.blurry),
        Copy.captureQualityBlur,
      );
      expect(
        ImageQuality.message(ImageQualityFinding.dark),
        Copy.captureQualityDark,
      );
      expect(
        ImageQuality.message(ImageQualityFinding.overexposed),
        Copy.captureQualityBright,
      );
      expect(
        ImageQuality.message(ImageQualityFinding.smallText),
        Copy.captureQualitySmallText,
      );
    });
  });
}
