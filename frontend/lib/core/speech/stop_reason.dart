/// Why a live transcription session stopped capturing (spec §30.4.5).
enum StopReason {
  /// The operator stopped it.
  user,

  /// Dictation heard nothing for its silence limit.
  silence,

  /// The request's own length limit was reached.
  maxDuration,

  /// The session reached the longest recording the app allows.
  sessionLimit,

  /// Storage ran out.
  storage,

  /// The app is closing, or dictation's app left the foreground.
  exit,

  /// Audio could no longer be kept, so the microphone stopped.
  captureFailed,

  /// Evidence capture took the microphone from dictation.
  preempted,
}
