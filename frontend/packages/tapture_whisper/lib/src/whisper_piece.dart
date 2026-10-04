import 'dart:typed_data';

/// One decoded text piece (whisper's token). Its bytes may be part of a UTF-8
/// sequence that the next piece completes.
final class WhisperPiece {
  /// Describes one piece.
  const WhisperPiece({
    required this.id,
    required this.bytes,
    required this.probability,
    required this.startMs,
    required this.endMs,
  });

  /// The piece's vocabulary id.
  final int id;

  /// The piece's UTF-8 bytes, possibly a partial sequence.
  final Uint8List bytes;

  /// The decoder's probability for the piece.
  final double probability;

  /// Where the piece starts, in milliseconds; -1 unless piece timestamps were
  /// asked for.
  final int startMs;

  /// Where the piece ends, in milliseconds; -1 unless piece timestamps were
  /// asked for.
  final int endMs;
}
