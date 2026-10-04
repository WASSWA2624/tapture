import 'whisper_segment.dart';

/// Everything one transcription produced, copied out of native memory.
final class WhisperTranscript {
  /// Describes one transcription.
  const WhisperTranscript({
    required this.segments,
    required this.language,
    required this.wallMs,
  });

  /// The decoded segments, in order.
  final List<WhisperSegment> segments;

  /// The language decoded, as whisper's code.
  final String language;

  /// Wall-clock time the native call took, in milliseconds.
  final int wallMs;
}
