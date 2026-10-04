import 'package:flutter/foundation.dart' show listEquals;

import 'speech_piece.dart';

/// One stretch of decoded text as the engine returned it, before the
/// pipeline cleans, filters or aligns it.
final class SpeechSegment {
  /// Describes raw [text] heard from [startSample] to [endSample].
  const SpeechSegment({
    required this.startSample,
    required this.endSample,
    required this.text,
    required this.noSpeechProbability,
    required this.averageLogProbability,
    required this.confidence,
    this.pieces = const <SpeechPiece>[],
  });

  /// First sample on the session timeline: the request's offset plus the
  /// engine's time, clamped into the decoded window.
  final int startSample;

  /// Sample after the last one, never past the window's original end.
  final int endSample;

  /// Raw decoded text, never logged.
  final String text;

  /// The model's probability that the window held no speech.
  final double noSpeechProbability;

  /// Mean log probability over every decoded step, timestamps included.
  final double averageLogProbability;

  /// Mean probability of the pieces, from 0 to 1.
  final double confidence;

  /// Timed pieces, present when the request asked for piece timings.
  final List<SpeechPiece> pieces;

  @override
  bool operator ==(Object other) =>
      other is SpeechSegment &&
      other.startSample == startSample &&
      other.endSample == endSample &&
      other.text == text &&
      other.noSpeechProbability == noSpeechProbability &&
      other.averageLogProbability == averageLogProbability &&
      other.confidence == confidence &&
      listEquals(other.pieces, pieces);

  @override
  int get hashCode => Object.hash(
    startSample,
    endSample,
    text,
    noSpeechProbability,
    averageLogProbability,
    confidence,
    Object.hashAll(pieces),
  );
}
