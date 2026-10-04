import 'package:flutter/foundation.dart' show listEquals;

import 'transcript_segment.dart';

/// One closed utterance and the segments it produced, handed to a
/// [TranscriptSink] as one durable write.
final class FinishedUtterance {
  /// Describes utterance [utteranceId] over samples [fromSample] to
  /// [toSample]. A [skipped] utterance was not transcribed and carries no
  /// segments; the sink records its range as a gap.
  const FinishedUtterance({
    required this.utteranceId,
    required this.fromSample,
    required this.toSample,
    required this.segments,
    this.skipped = false,
  });

  /// The utterance's place in the session, from 1.
  final int utteranceId;

  /// First sample of the utterance on the session timeline.
  final int fromSample;

  /// Sample after the utterance's last one.
  final int toSample;

  /// The segments decoded from it, in time order; empty when [skipped] or
  /// when it held no words.
  final List<TranscriptSegment> segments;

  /// Whether the range was left untranscribed, so the transcript has a gap.
  final bool skipped;

  @override
  bool operator ==(Object other) =>
      other is FinishedUtterance &&
      other.utteranceId == utteranceId &&
      other.fromSample == fromSample &&
      other.toSample == toSample &&
      other.skipped == skipped &&
      listEquals(other.segments, segments);

  @override
  int get hashCode => Object.hash(
    utteranceId,
    fromSample,
    toSample,
    skipped,
    Object.hashAll(segments),
  );
}
