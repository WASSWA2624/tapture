part of 'live_transcription_event.dart';

/// The session failed and stopped.
final class TranscriptionFailed extends LiveTranscriptionEvent {
  /// A failure for [failure].
  const TranscriptionFailed({required this.failure});

  /// Why the session failed.
  final Failure failure;
}
