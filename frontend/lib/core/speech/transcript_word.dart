import 'package:tapture/core/errors/failure.dart';

/// One word of a finished transcript segment, timed on the session
/// timeline at 16 kHz.
final class TranscriptWord {
  /// Describes [text] heard from [startSample] to [endSample].
  const TranscriptWord({
    required this.text,
    required this.startSample,
    required this.endSample,
    required this.probability,
  });

  /// Rebuilds a word written by [toJson]. A malformed map throws
  /// [CorruptionFailure].
  factory TranscriptWord.fromJson(Map<String, Object?> json) {
    final Object? text = json[_text];
    final Object? start = json[_start];
    final Object? end = json[_end];
    final Object? probability = json[_probability];
    if (text is! String ||
        start is! int ||
        end is! int ||
        probability is! num) {
      throw const CorruptionFailure();
    }
    return TranscriptWord(
      text: text,
      startSample: start,
      endSample: end,
      probability: probability.toDouble(),
    );
  }

  /// The word as decoded, without surrounding spaces. Never logged.
  final String text;

  /// First sample of the word.
  final int startSample;

  /// Sample after the word's last one.
  final int endSample;

  /// The model's probability for the word, from 0 to 1.
  final double probability;

  /// This word as a JSON map.
  Map<String, Object?> toJson() => <String, Object?>{
    _text: text,
    _start: startSample,
    _end: endSample,
    _probability: probability,
  };

  @override
  bool operator ==(Object other) =>
      other is TranscriptWord &&
      other.text == text &&
      other.startSample == startSample &&
      other.endSample == endSample &&
      other.probability == probability;

  @override
  int get hashCode => Object.hash(text, startSample, endSample, probability);
}

const String _text = 'text';
const String _start = 'startSample';
const String _end = 'endSample';
const String _probability = 'probability';
