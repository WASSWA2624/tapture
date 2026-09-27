/// What this device knows of a package's project (task 076, W19).
enum PackagePresence {
  /// Never seen here: the package imports as a new project.
  absent,

  /// Here and live: the package merges into it.
  live,

  /// Deleted here: refused, since a merge never brings back what was
  /// deleted (specification §44).
  deleted,
}
