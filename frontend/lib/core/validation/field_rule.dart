/// The slice of a template field the validation engine reads (task 015).
///
/// Features map their own field type onto this. The engine stays free of
/// Flutter, Drift and feature imports (FE-STR-04, FE-STR-05).
final class FieldRule {
  /// Creates a rule for [fieldKey].
  const FieldRule({
    required this.fieldKey,
    required this.label,
    this.required = false,
    this.recommended = false,
    this.identity = false,
    this.requiresEvidence = false,
    this.requiredWhen,
    this.pattern,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.options = const <String>[],
    this.unit,
    this.computedExpression,
    this.hidden = false,
  });

  /// Stable key within the template.
  final String fieldKey;

  /// Operator-facing label.
  final String label;

  /// Always required, whatever the other values are.
  final bool required;

  /// Soft: a warning when empty, never a block.
  final bool recommended;

  /// Identifies the record. Empty blocks approval.
  final bool identity;

  /// The record must hold evidence before approval.
  final bool requiresEvidence;

  /// Expression that makes this field required when it evaluates true.
  final String? requiredWhen;

  /// Regular expression the text must match, when set.
  final String? pattern;

  /// Shortest accepted text, when set.
  final int? minLength;

  /// Longest accepted text, when set.
  final int? maxLength;

  /// Lowest accepted number, when set.
  final num? min;

  /// Highest accepted number, when set.
  final num? max;

  /// Allowed choices. Empty means the field is not a closed list.
  final List<String> options;

  /// Unit the value must be expressible in, when set.
  final String? unit;

  /// Arithmetic expression of a computed field, when set.
  final String? computedExpression;

  /// Hidden fields are not checked.
  final bool hidden;
}
