part of 'live_transcription_event.dart';

/// A finished segment, reported after the sink's write was attempted.
final class SegmentFinalized extends LiveTranscriptionEvent {
  /// Reports [segment], [durable] once the sink stored it.
  const SegmentFinalized({required this.segment, required this.durable});

  /// The segment as stored.
  final TranscriptSegment segment;

  /// False only when the sink failed: the segment is kept in memory to
  /// retry.
  final bool durable;
}
