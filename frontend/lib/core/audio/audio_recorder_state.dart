part of 'audio_recorder_service.dart';

/// Recorder lifecycle phase.
enum AudioRecorderPhase {
  /// Not recording.
  idle,

  /// Writing chunks.
  recording,

  /// Elapsed frozen; file still open.
  paused,
}

/// Snapshot of the recorder for UI.
final class AudioRecorderState {
  /// Creates a state.
  const AudioRecorderState({
    required this.phase,
    this.elapsed = Duration.zero,
    this.level = 0,
  });

  /// Current phase.
  final AudioRecorderPhase phase;

  /// Time recorded so far.
  final Duration elapsed;

  /// Input level 0–1.
  final double level;
}
