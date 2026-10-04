/// Why the native library cannot be used here.
enum WhisperUnavailableReason {
  /// This operating system has no build of the library.
  unsupportedPlatform,

  /// No candidate library could be opened.
  libraryMissing,

  /// The library speaks a different ABI or struct layout.
  abiMismatch,

  /// The processor lacks a feature the engine was compiled for; the library
  /// was not opened.
  unsupportedCpu,

  /// The library is a stub without the engine on this architecture.
  engineNotBuilt,
}
