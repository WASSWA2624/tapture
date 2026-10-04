/// Why a speech engine runtime cannot transcribe on this device.
enum SpeechUnavailableReason {
  /// This platform has no speech engine.
  platform,

  /// The native or WebAssembly library could not be opened.
  library,

  /// The library speaks a different C ABI version.
  abi,

  /// The processor lacks an instruction set the library was built for.
  cpu,

  /// This build ships a stub library without the engine.
  engineNotBuilt,

  /// The browser lacks WebAssembly SIMD.
  simd,
}
