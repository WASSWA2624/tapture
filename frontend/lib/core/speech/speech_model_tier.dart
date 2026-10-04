/// The speed-for-accuracy trade a whisper model makes.
enum SpeechModelTier {
  /// Smallest and quickest; the floor every capable device can run.
  fast,

  /// The default on devices with the memory and cores to spare.
  balanced,

  /// Largest and slowest; offered only where it fits.
  accurate,
}
