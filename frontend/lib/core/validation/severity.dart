/// How serious a [ValidationIssue] is (task 015).
///
/// An error blocks a save, an approval and an export. A warning never does.
enum Severity {
  /// Blocks until the value is fixed.
  error,

  /// Shown, and the form stays submittable.
  warning,
}
