/// What two devices disagree about (task 076, W21).
enum ConflictKind {
  /// A field's value.
  value,

  /// A record's or a photo's caption.
  caption,

  /// A record's status.
  status,

  /// Deleted on the other device, changed here after that.
  deletedThere,

  /// Deleted here, changed on the other device after that.
  deletedHere,
}
