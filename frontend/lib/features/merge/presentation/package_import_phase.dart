/// Where bringing a package in stands (task 076, W19).
enum PackageImportPhase {
  /// No package is open.
  idle,

  /// The chosen package is being opened and checked.
  checking,

  /// A checked package is open, waiting for a choice.
  ready,

  /// The package is being written as a new project, or merged.
  writing,
}
