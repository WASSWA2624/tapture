import 'whisper_log_level.dart';

/// One line drained from the library's log ring. The library never writes a
/// model path, a prompt or transcript text into it.
final class WhisperLogLine {
  /// Describes one drained line.
  const WhisperLogLine({required this.level, required this.message});

  /// How severe the line is.
  final WhisperLogLevel level;

  /// The line, without its trailing newline.
  final String message;
}
