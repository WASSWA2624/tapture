/// Whether on-device speech can run here now, and if not, why (spec
/// §30.4.2). Each verdict but [ready] maps to one failure of spec §30.4.4.
enum SpeechVerdict {
  /// A model is chosen and can be loaded.
  ready,

  /// The engine library is absent, unopenable or of another ABI.
  engineMissing,

  /// The processor, word size, memory, cores or browser cannot run it.
  unsupportedDevice,

  /// The voice detector or the fast model is absent or damaged.
  modelMissing,

  /// Not even the fast model fits in the memory free now. Transient: the
  /// next check decides again.
  lowMemory,

  /// The voice language has no whisper model.
  languageUnsupported,
}
