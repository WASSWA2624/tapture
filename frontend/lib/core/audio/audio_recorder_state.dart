part of 'audio_recorder_service.dart';

/// Recorder lifecycle phase.
enum AudioRecorderPhase {
  /// Not recording.
  idle,

  /// Waiting for microphone permission.
  permission,

  /// Writing chunks.
  recording,

  /// Elapsed frozen; file still open.
  paused,

  /// Recorder stopped; the project file is being flushed and hashed.
  finalizing,

  /// The last attempt failed and may be retried.
  failed,

  /// The file is durable and metadata is available.
  completed,
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
