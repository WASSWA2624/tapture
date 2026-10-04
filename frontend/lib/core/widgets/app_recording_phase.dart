/// Where a recording stands, which decides the controls an `AppRecordingBar`
/// offers.
enum AppRecordingPhase {
  /// Nothing is recording. The bar offers start when the caller can start.
  idle,

  /// The microphone is opening. Controls wait, and stop shows it is busy.
  starting,

  /// Audio is being recorded. Pause, stop and discard are offered.
  recording,

  /// The recording is open but paused. Resume, stop and discard are offered.
  paused,

  /// The recording is closing. Controls wait, and stop shows it is busy.
  finishing,
}
