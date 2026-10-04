/// Why an utterance closed (spec §30.4.7).
enum UtteranceEndReason {
  /// Speech paused for the end-silence span.
  silence,

  /// The utterance had passed its soft length and speech dipped.
  softCut,

  /// The utterance reached its maximum length during continuous speech and
  /// was cut at its quietest moment; the next one re-reads the seam.
  hardCut,

  /// Capture paused.
  pause,

  /// Capture stopped.
  stop,
}
