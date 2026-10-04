/// What a live transcription session is for (spec §30.4.5).
enum TranscriptionKind {
  /// Field dictation: memory-only, stopped by silence, a time limit or the
  /// app leaving the foreground, and given way to evidence capture.
  dictation,

  /// A long-form recording whose audio is kept as evidence and whose
  /// transcript is written beside it.
  longForm,
}
