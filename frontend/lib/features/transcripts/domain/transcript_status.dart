/// Where a transcript is in its life, stored as the value's name.
enum TranscriptStatus {
  /// Still being recorded or finished. It takes new segments, refuses
  /// edits, and is left out of record search.
  live,

  /// Every captured sample was transcribed or recorded as a gap.
  complete,

  /// It stopped before the audio was accounted for: the app was closed, or
  /// the rest was skipped.
  interrupted;

  /// Whether the transcript has stopped taking segments, so it can be
  /// edited and searched.
  bool get settled => this != live;
}
