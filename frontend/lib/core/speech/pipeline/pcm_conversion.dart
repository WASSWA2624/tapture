import 'dart:typed_data';

import 'package:tapture/core/audio/pcm_level_meter.dart';

/// Converts captured 16-bit samples into what the speech engine reads and
/// measures their loudness (spec §30.4.7).
abstract final class PcmConversion {
  /// Writes `src[from, to)` into [dst] from [at] as floats in [-1, 1), the
  /// normalisation whisper.cpp's own examples use. [dst] is reused by the
  /// caller, so nothing is allocated per call.
  static void toFloat32(
    Int16List src,
    Float32List dst, {
    int from = 0,
    int? to,
    int at = 0,
  }) {
    final int end = to ?? src.length;
    for (int index = from; index < end; index++) {
      dst[at + index - from] = src[index] / 32768;
    }
  }

  /// Root-mean-square loudness of `samples[from, to)` in dBFS, never below
  /// [PcmLevelMeter.floorDbfs]; the same scale the level meter shows.
  static double rmsDbfs(Int16List samples, int from, int to) {
    if (to <= from) {
      return PcmLevelMeter.floorDbfs;
    }
    double squares = 0;
    for (int index = from; index < to; index++) {
      final double sample = samples[index].toDouble();
      squares += sample * sample;
    }
    return PcmLevelMeter.dbfsOf(squares / (to - from));
  }
}
