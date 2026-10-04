import 'package:tapture/core/speech/transcript_segment.dart';

/// One stored segment of a transcript, as it reads back: where it sits in
/// the recording and the text heard there (spec §30.4.6).
final class TranscriptLine {
  /// Describes [text] heard from [start] to [end], the [seq]th segment
  /// written.
  const TranscriptLine({
    required this.seq,
    required this.start,
    required this.end,
    required this.text,
    this.confidence,
  });

  /// The line a committed [segment] is stored as, its times to the
  /// millisecond.
  factory TranscriptLine.fromSegment(TranscriptSegment segment) {
    return TranscriptLine(
      seq: segment.id,
      start: Duration(milliseconds: segment.start.inMilliseconds),
      end: Duration(milliseconds: segment.end.inMilliseconds),
      text: segment.text,
      confidence: segment.confidence,
    );
  }

  /// 1-based insertion order within the transcript.
  final int seq;

  /// Where the segment starts in the recording.
  final Duration start;

  /// Where the segment ends in the recording.
  final Duration end;

  /// The text as decoded. Never logged.
  final String text;

  /// Mean word probability from 0 to 1, when the decode reported one.
  final double? confidence;

  @override
  bool operator ==(Object other) =>
      other is TranscriptLine &&
      other.seq == seq &&
      other.start == start &&
      other.end == end &&
      other.text == text &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(seq, start, end, text, confidence);
}
