/// Where the utterance segmenter stands between two detector frames
/// (spec §30.4.7).
enum SegmenterPhase {
  /// No utterance is open and no speech is building.
  silence,

  /// Speech has started but has not lasted long enough to open an
  /// utterance; a click ends here.
  onset,

  /// An utterance is open and speech continues.
  speech,

  /// An utterance is open and speech has paused; it closes when the pause
  /// lasts long enough.
  hangover,
}
