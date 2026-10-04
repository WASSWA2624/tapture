/// Where a surface's live transcript session stands, as its controller
/// reports it.
enum TranscriptSessionPhase {
  /// Nothing is recording.
  idle,

  /// The transcript row is being written and the microphone is opening.
  starting,

  /// Audio is being recorded and transcribed.
  recording,

  /// The recording is open but paused; it resumes only when asked.
  paused,

  /// The recording is stopping, and its audio is being filed and linked.
  finishing,

  /// The audio is filed and linked. The transcript may still be finishing
  /// under the speech service.
  saved,

  /// Starting or filing failed. Whatever was recorded is kept.
  failed,
}
