import 'package:flutter/foundation.dart' show listEquals;

/// What a live transcript shows from moment to moment: the settled
/// paragraphs, the words still being recognised, the time recorded and
/// the input level. It changes many times a second, so it is published
/// through a `ValueListenable`, never as provider state.
final class LiveTranscriptFrame {
  /// A frame of [paragraphs] then [tentative] words after [elapsed] of
  /// audio at input [level] (0 to 1).
  const LiveTranscriptFrame({
    this.paragraphs = const <String>[],
    this.tentative = '',
    this.elapsed = Duration.zero,
    this.level = 0,
  });

  /// Nothing recorded yet.
  static const LiveTranscriptFrame empty = LiveTranscriptFrame();

  /// Settled paragraphs, oldest first. Never logged.
  final List<String> paragraphs;

  /// Words of the utterance still being recognised. Never logged.
  final String tentative;

  /// Audio recorded so far, paused time excluded.
  final Duration elapsed;

  /// The latest input level, from 0 to 1.
  final double level;

  /// This frame with the given parts replaced.
  LiveTranscriptFrame copyWith({
    List<String>? paragraphs,
    String? tentative,
    Duration? elapsed,
    double? level,
  }) {
    return LiveTranscriptFrame(
      paragraphs: paragraphs ?? this.paragraphs,
      tentative: tentative ?? this.tentative,
      elapsed: elapsed ?? this.elapsed,
      level: level ?? this.level,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LiveTranscriptFrame &&
      listEquals(other.paragraphs, paragraphs) &&
      other.tentative == tentative &&
      other.elapsed == elapsed &&
      other.level == level;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(paragraphs), tentative, elapsed, level);
}
