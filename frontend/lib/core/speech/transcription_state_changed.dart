part of 'live_transcription_event.dart';

/// The session moved to another phase.
final class TranscriptionStateChanged extends LiveTranscriptionEvent {
  /// The session is now in [phase], paused for [reason] when paused.
  const TranscriptionStateChanged({required this.phase, this.reason});

  /// The phase the session is in.
  final LiveTranscriptionPhase phase;

  /// Why capture paused, while [phase] is paused.
  final CapturePauseReason? reason;
}
