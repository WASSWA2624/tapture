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

  /// Both records hold a photo with the same content hash (task 015).
  samePhoto,

  /// A photo is within the perceptual-hash distance of the other's (task 015).
  nearPhoto,

  /// The same predefined template row in the same context (task 015).
  predefinedRow,

  /// The same name in the same context inside the duplicate time window
  /// (task 015).
  nameContextTime,
}
