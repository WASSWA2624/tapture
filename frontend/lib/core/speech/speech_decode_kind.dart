/// Why a window is decoded, which decides how the engine queues it.
enum SpeechDecodeKind {
  /// A draft of a still-open utterance. Disposable: a newer interim of the
  /// same lease replaces a pending one, and any committed request preempts
  /// one in flight.
  interim,

  /// The final text of a closed utterance. Queued in order and never
  /// dropped.
  committed,
}
