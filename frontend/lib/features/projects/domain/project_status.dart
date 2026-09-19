/// Lifecycle of a [Project].
enum ProjectStatus {
  /// Open for capture and listed by default.
  active,

  /// Hidden from the default list; reversible with nothing lost.
  archived,

  /// Soft-deleted; recoverable until the retention window ends.
  deleted,
}
