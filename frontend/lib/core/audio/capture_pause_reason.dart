/// Why a streaming capture stopped taking audio for a while.
enum CapturePauseReason {
  /// The operator paused.
  user,

  /// The app left the foreground.
  background,

  /// The platform paused the microphone for a call or another app.
  interruption,

  /// The microphone stream ended or failed, for example when it was
  /// unplugged.
  microphoneLost,

  /// The microphone permission was taken away while recording.
  permissionRevoked,
}
