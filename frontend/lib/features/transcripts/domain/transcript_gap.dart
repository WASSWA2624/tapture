/// A stretch of the recording left untranscribed, which "Finish the
/// transcript" can fill later (spec §30.4.6).
final class TranscriptGap {
  /// Describes the audio from [start] to [end].
  const TranscriptGap({required this.start, required this.end});

  /// Where the gap starts in the recording.
  final Duration start;

  /// Where the gap ends in the recording.
  final Duration end;

  /// How much audio the gap holds.
  Duration get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is TranscriptGap && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
