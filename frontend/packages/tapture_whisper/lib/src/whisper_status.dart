/// What a native call reported: `tw_status` of `src/tapture_whisper.h`, in
/// code order, so a value's [index] is its native code.
enum WhisperStatus {
  /// The call succeeded.
  ok,

  /// A null or out-of-range argument, or an empty, `auto` or unknown
  /// language.
  invalidArgument,

  /// A struct size differs between this package and the library.
  abiMismatch,

  /// The processor lacks a feature the engine was compiled for.
  unsupportedCpu,

  /// The model file is missing or unreadable.
  fileOpen,

  /// The model has a bad magic number or header.
  modelInvalid,

  /// The verified model failed to load.
  modelLoad,

  /// An allocation failed.
  outOfMemory,

  /// The abort cell reached the job id; any partial result was discarded.
  aborted,

  /// whisper.cpp failed; see `WhisperNativeException.whisperCode`.
  inference,

  /// The model lost its decoder state and must be closed.
  poisoned,

  /// Another call is running on the same handle.
  busy,

  /// More samples than one call accepts.
  audioTooLong,

  /// The library is a stub without the engine on this architecture.
  engineNotBuilt,

  /// The library hit an unexpected failure.
  internal,

  /// The model's size or SHA-256 differs from the expectation.
  modelMismatch;

  /// The native code of this status.
  int get code => index;

  /// The status for a native [code]; an unknown code reads as [internal].
  static WhisperStatus fromCode(int code) =>
      code >= 0 && code < values.length ? values[code] : internal;
}
