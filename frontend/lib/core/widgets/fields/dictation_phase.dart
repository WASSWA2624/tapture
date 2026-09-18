/// Where one field's dictation is, so the field can say so.
enum DictationPhase {
  /// Not listening. The microphone offers to start.
  idle,

  /// The recogniser is opening; the operator may be answering a
  /// microphone prompt.
  starting,

  /// Words are being heard.
  listening,

  /// Stopped; the last words are on their way into the field.
  finishing,
}
