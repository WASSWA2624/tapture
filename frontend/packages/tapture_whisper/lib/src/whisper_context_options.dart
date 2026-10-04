/// How a model or VAD handle is opened (`tw_context_options`).
final class WhisperContextOptions {
  /// Describes the options; the defaults equal `tw_context_options_init`.
  const WhisperContextOptions({this.threads = 4, this.flashAttention = true});

  /// Compute threads, clamped by the library to `[1, min(hardware, 8)]`.
  final int threads;

  /// Whether whisper uses flash attention; ignored by VAD.
  final bool flashAttention;
}
