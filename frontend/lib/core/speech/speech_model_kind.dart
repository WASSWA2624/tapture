/// What a speech model file does, which decides how its header is checked.
enum SpeechModelKind {
  /// A whisper transcription model, checked by magic and hyperparameters.
  whisper,

  /// A voice-activity model, checked by magic only.
  vad,
}
