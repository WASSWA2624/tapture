part of 'audio_capture_event.dart';

/// The input level over the last `AppConstants.audio.meterTick` of audio.
final class CaptureLevel extends AudioCaptureEvent {
  /// A level of [level] (0 to 1) measured as [dbfs].
  const CaptureLevel({required this.level, required this.dbfs});

  /// Loudness mapped to 0 to 1 for a meter: −60 dBFS and below read 0.
  final double level;

  /// Root-mean-square loudness in decibels below full scale.
  final double dbfs;
}
