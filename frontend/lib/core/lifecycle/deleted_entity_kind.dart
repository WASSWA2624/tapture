/// Durable entities presented by the shared recycle bin.
enum DeletedEntityKind {
  /// A project and its managed contents.
  project,

  /// A captured record.
  record,

  /// A database-owned photo.
  photo,

  /// A database-owned document attachment.
  document,

  /// A database-owned audio attachment.
  audio,
}
