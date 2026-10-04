import 'dart:math' as math;
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';

import 'audio_capture_event.dart';

/// Measures the input level from the captured samples themselves, one
/// [CaptureLevel] per `AppConstants.audio.meterTick` of audio, so no
/// platform amplitude poll is needed.
final class PcmLevelMeter {
  /// A meter over windows of [windowSamples], by default one meter tick of
  /// 16 kHz audio.
  PcmLevelMeter({int? windowSamples})
    : windowSamples =
          windowSamples ??
          AppConstants.audio.meterTick.inMicroseconds *
              AppConstants.audio.sampleRate ~/
              Duration.microsecondsPerSecond;

  /// Samples in each measured window.
  final int windowSamples;

  /// The quietest level reported, for digital silence.
  static const double floorDbfs = -90;

  /// The level a meter shows as empty.
  static const double _emptyDbfs = -60;

  double _squares = 0;
  int _count = 0;

  /// Adds [samples] and returns one level for every window they complete.
  List<CaptureLevel> add(Int16List samples) {
    final List<CaptureLevel> levels = <CaptureLevel>[];
    for (int index = 0; index < samples.length; index++) {
      final double sample = samples[index].toDouble();
      _squares += sample * sample;
      _count++;
      if (_count == windowSamples) {
        final double dbfs = dbfsOf(_squares / _count);
        levels.add(CaptureLevel(level: levelOf(dbfs), dbfs: dbfs));
        _squares = 0;
        _count = 0;
      }
    }
    return levels;
  }

  /// Root-mean-square loudness of samples whose squares average
  /// [meanSquare], in decibels below a full-scale 16-bit sample, never
  /// below [floorDbfs]. A full-scale sine reads about −3 dBFS.
  static double dbfsOf(double meanSquare) {
    if (meanSquare <= 0) {
      return floorDbfs;
    }
    final double dbfs =
        20 * math.log(math.sqrt(meanSquare) / 32768) / math.ln10;
    return math.max(floorDbfs, dbfs);
  }

  /// [dbfs] on a 0 to 1 meter: −60 dBFS and below read 0, full scale 1.
  static double levelOf(double dbfs) {
    return ((dbfs - _emptyDbfs) / -_emptyDbfs).clamp(0, 1).toDouble();
  }
}
