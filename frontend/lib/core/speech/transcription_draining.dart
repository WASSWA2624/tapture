part of 'live_transcription_event.dart';

/// Capture has stopped and finals are still being transcribed.
final class TranscriptionDraining extends LiveTranscriptionEvent {
  /// [pending] audio is still to be transcribed.
  const TranscriptionDraining({required this.pending});

  /// Audio still waiting for its final.
  final Duration pending;
}
