/// How far a speech pipeline has stepped back because finals are waiting
/// (spec §30.4.7). Each level is entered above its backlog and left below
/// `finalBacklogRecover`.
enum BackpressureLevel {
  /// Finals keep up: open utterances are drafted.
  normal,

  /// Finals lag beyond `finalBacklogInterimsOff`: drafts are off and the
  /// session warns that transcription is behind.
  interimsOff,

  /// Finals lag beyond `finalBacklogReducedContext`: drafts are off and
  /// finals encode only their own audio plus a short pad.
  reducedContext,
}
