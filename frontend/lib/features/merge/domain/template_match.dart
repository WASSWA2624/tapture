import 'compatibility_issue.dart';

/// How one incoming template lines up with this device (task 076, W20): the
/// local template it maps onto, if any, and every issue found, each naming
/// the field it concerns. Names and labels are template data.
final class TemplateMatch {
  /// Creates a match.
  const TemplateMatch({
    required this.incomingId,
    required this.name,
    required this.templateKey,
    required this.issues,
    this.localId,
  });

  /// The template's id in the package.
  final String incomingId;

  /// Its name, as the package holds it.
  final String name;

  /// Its stable key, empty when it has none.
  final String templateKey;

  /// The local template its records join, or null when there is none.
  final String? localId;

  /// Issues found, each with the field it concerns (empty for the whole
  /// template).
  final List<({CompatibilityIssue issue, String field})> issues;

  /// Whether any issue stops the merge.
  bool get blocks => issues.any(
    (({CompatibilityIssue issue, String field}) found) => found.issue.blocks,
  );
}
