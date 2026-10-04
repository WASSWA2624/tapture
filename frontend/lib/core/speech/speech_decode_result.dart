import 'package:flutter/foundation.dart' show listEquals;
import 'package:tapture/core/constants/app_constants.dart';

import 'speech_piece.dart';
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

  /// This result limited to the [sampleCount] samples the request really
  /// carried, after an engine padded a short window: a segment or piece
  /// starting at or past the original end came from padding and is dropped,
  /// and every other time is held inside the window.
  SpeechDecodeResult clampedTo(int sampleCount) {
    final int end = offsetSamples + sampleCount;
    return SpeechDecodeResult(
      segments: <SpeechSegment>[
        for (final SpeechSegment segment in segments)
          if (segment.startSample < end)
            _clampedSegment(segment, offsetSamples, end),
      ],
      language: language,
      offsetSamples: offsetSamples,
      sampleCount: sampleCount,
      elapsed: elapsed,
    );
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

SpeechSegment _clampedSegment(SpeechSegment segment, int offset, int end) {
  final int start = _bounded(segment.startSample, offset, end);
  return SpeechSegment(
    startSample: start,
    endSample: _bounded(segment.endSample, start, end),
    text: segment.text,
    noSpeechProbability: segment.noSpeechProbability,
    averageLogProbability: segment.averageLogProbability,
    confidence: segment.confidence,
    pieces: <SpeechPiece>[
      for (final SpeechPiece piece in segment.pieces)
        if (piece.startSample < end) _clampedPiece(piece, offset, end),
    ],
  );
}

SpeechPiece _clampedPiece(SpeechPiece piece, int offset, int end) {
  final int start = _bounded(piece.startSample, offset, end);
  return SpeechPiece(
    startSample: start,
    endSample: _bounded(piece.endSample, start, end),
    text: piece.text,
    probability: piece.probability,
  );
}

/// [sample] held inside `[low, high]`.
int _bounded(int sample, int low, int high) =>
    sample < low ? low : (sample > high ? high : sample);
