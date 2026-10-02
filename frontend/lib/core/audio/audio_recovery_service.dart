import 'package:tapture/core/errors/result.dart';

import 'audio_recording.dart';

/// Recovers a staged take after a process interruption. Implementations keep
/// the original staged bytes when repairing a container header.
abstract interface class AudioRecoveryService {
  /// Publishes the take at [relativePath], or returns null if recording never
  /// produced a file. Duration comes from the audio samples, not wall time.
  Future<Result<AudioRecording?>> recover(String relativePath);
}
