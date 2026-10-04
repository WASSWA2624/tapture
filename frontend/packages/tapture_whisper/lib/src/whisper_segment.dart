import 'dart:typed_data';

import 'whisper_piece.dart';

/// One decoded segment of a transcription.
final class WhisperSegment {
  /// Describes one segment.
  const WhisperSegment({
    required this.startMs,
    required this.endMs,
    required this.textBytes,
    required this.text,
    required this.noSpeechProbability,
    required this.averageLogProbability,
    required this.meanProbability,
    required this.minProbability,
    required this.pieces,
  });

  /// Where the segment starts, in milliseconds from the start of the audio.
  final int startMs;

  /// Where the segment ends, in milliseconds from the start of the audio.
  final int endMs;

  /// The segment's text exactly as whisper produced it, in UTF-8.
  final Uint8List textBytes;

  /// [textBytes] decoded; a sequence split at a segment boundary reads as
  /// U+FFFD.
  final String text;

  /// whisper's probability that the window holds no speech.
  final double noSpeechProbability;

  /// The mean log probability over every piece, timestamps included.
  final double averageLogProbability;

  /// The mean probability over the text pieces, or 0 without any.
  final double meanProbability;

  /// The lowest probability of a text piece, or 0 without any.
  final double minProbability;

  /// The segment's text pieces, in order.
  final List<WhisperPiece> pieces;
}
