/// Why two records may be the same thing captured twice (specification §40,
/// task 076, W22). A signal only suggests; a person decides.
enum DuplicateSignal {
  /// Every identity field both records fill holds the same value.
  identity,

  /// Both records hold the very same photo.
  photo,

  /// The same context, captured close together, with near-identical
  /// captions.
  caption,
}
