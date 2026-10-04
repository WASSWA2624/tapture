import 'package:tapture/core/speech/speech_text.dart';

import 'transcript_line.dart';
import 'transcript_summary.dart';

/// A whole transcript: its header, its raw lines in reading order, and the
/// operator's edit beside them (spec §30.4.6).
final class Transcript {
  /// Describes the transcript [summary] names.
  const Transcript({
    required this.summary,
    required this.lines,
    this.editedText,
    this.editedAt,
  });

  /// The header.
  final TranscriptSummary summary;

  /// The raw lines in reading order: by start time, then insertion order,
  /// so a gap filled later slots into place.
  final List<TranscriptLine> lines;

  /// The operator's edit, when one stands. Never logged.
  final String? editedText;

  /// When the edit was last written or cleared.
  final DateTime? editedAt;

  /// The raw text, lines joined with one space. Never logged.
  String get rawText =>
      SpeechText.join(lines.map((TranscriptLine l) => l.text));

  /// What the transcript reads as: the edit when one stands, else the raw
  /// text.
  String get displayText => editedText ?? rawText;

  /// The id the next committed segment takes: segments are numbered from 1
  /// with no gaps.
  int get nextSegmentId => lines.length + 1;
}
