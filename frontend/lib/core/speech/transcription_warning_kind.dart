/// What a live transcription session warns about without stopping
/// (spec §30.4.5).
enum TranscriptionWarningKind {
  /// Transcription cannot run; audio is still recorded.
  transcriptionUnavailable,

  /// Transcription lags behind the audio.
  engineBehind,

  /// An utterance could not be transcribed and is recorded as a gap.
  utteranceSkipped,

  /// Transcript text could not be saved yet; it is kept to retry.
  transcriptUnsaved,

  /// Storage is running low.
  storageLow,

  /// Storage ran out, so recording stopped.
  storageStop,

  /// The session reached its length limit.
  sessionLimit,
}
