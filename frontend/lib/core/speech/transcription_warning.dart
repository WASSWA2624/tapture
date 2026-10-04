part of 'live_transcription_event.dart';

/// Something went wrong without stopping the session.
final class TranscriptionWarning extends LiveTranscriptionEvent {
  /// A warning of [kind], with the transcription [lag] and the failure that
  /// [cause]d it where they apply.
  const TranscriptionWarning({required this.kind, this.lag, this.cause});

  /// What the warning is about.
  final TranscriptionWarningKind kind;

  /// How far transcription lags behind the audio, when it does.
  final Duration? lag;

  /// The failure behind the warning, if any.
  final Failure? cause;
}
