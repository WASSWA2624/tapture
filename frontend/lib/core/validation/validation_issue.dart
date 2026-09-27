import 'severity.dart';

/// One problem a validation pass found (task 015).
///
/// [fieldKey] is null for a problem about the whole record or the export
/// set. [message] is plain language a person can act on.
final class ValidationIssue {
  /// Creates an issue on [fieldKey] at [severity].
  const ValidationIssue(this.fieldKey, this.severity, this.message);

  /// The field the issue belongs to, or null when it is not one field.
  final String? fieldKey;

  /// Whether this blocks, or only warns.
  final Severity severity;

  /// What is wrong, in plain language.
  final String message;

  /// Whether this issue blocks a save, an approval or an export.
  bool get blocks => severity == Severity.error;

  @override
  bool operator ==(Object other) {
    return other is ValidationIssue &&
        other.fieldKey == fieldKey &&
        other.severity == severity &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(fieldKey, severity, message);
}
