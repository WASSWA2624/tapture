/// How whisper picks the next piece (`tw_strategy`), in code order.
enum WhisperStrategy {
  /// The most likely piece, with `bestOf` candidates on a temperature
  /// fallback.
  greedy,

  /// Beam search over `beamSize` beams.
  beam,
}
