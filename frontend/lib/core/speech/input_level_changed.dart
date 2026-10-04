part of 'live_transcription_event.dart';

/// The microphone's input level changed.
final class InputLevelChanged extends LiveTranscriptionEvent {
  /// A level of [level] (0 to 1) measured as [dbfs].
  const InputLevelChanged({required this.level, required this.dbfs});

  /// Loudness mapped to 0 to 1 for a meter.
  final double level;

  /// Root-mean-square loudness in decibels below full scale.
  final double dbfs;
}
