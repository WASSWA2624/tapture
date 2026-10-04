/// Where a live transcription session stands (spec §30.4.5).
enum LiveTranscriptionPhase {
  /// The microphone, permission, staging and stream are being set up.
  preparing,

  /// Audio is being captured.
  listening,

  /// Capture is paused; the pause reason says why.
  paused,

  /// Capture is stopping and the audio is being published.
  stopping,

  /// The audio is published and the transcript is still being finished.
  draining,

  /// The session ended and its transcript is written.
  completed,

  /// The session was cancelled; its audio is kept unpublished.
  cancelled,

  /// The session failed.
  failed,
}
