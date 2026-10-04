import 'package:flutter/foundation.dart' show listEquals;
import 'package:tapture/core/constants/app_constants.dart';

import 'speech_segment.dart';

/// What one decode produced.
final class SpeechDecodeResult {
  /// Reports [segments] decoded in [language] from [sampleCount] samples at
  /// [offsetSamples], taking [elapsed].
  const SpeechDecodeResult({
    required this.segments,
    required this.language,
    required this.offsetSamples,
    required this.sampleCount,
    required this.elapsed,
  });

  /// The decoded segments in time order, on the session timeline.
  final List<SpeechSegment> segments;

  /// The whisper language code the window was decoded in.
  final String language;

  /// The request's timeline offset.
  final int offsetSamples;

  /// Samples the request carried, before any padding the engine added.
  final int sampleCount;

  /// Compute time of the decode.
  final Duration elapsed;

  /// Compute time over audio time; below 1 is faster than real time, and 0
  /// for an empty window.
  double get realTimeFactor {
    if (sampleCount <= 0) {
      return 0;
    }
    final double audioMicroseconds =
        sampleCount *
        Duration.microsecondsPerSecond /
        AppConstants.audio.sampleRate;
    return elapsed.inMicroseconds / audioMicroseconds;
  }

  @override
  bool operator ==(Object other) =>
      other is SpeechDecodeResult &&
      other.language == language &&
      other.offsetSamples == offsetSamples &&
      other.sampleCount == sampleCount &&
      other.elapsed == elapsed &&
      listEquals(other.segments, segments);

  @override
  int get hashCode => Object.hash(
    language,
    offsetSamples,
    sampleCount,
    elapsed,
    Object.hashAll(segments),
  );
}
