/// One field's register value against what was found (task 015).
final class FieldVariance {
  /// Creates a variance for [fieldKey].
  const FieldVariance(this.fieldKey, this.recorded, this.found, this.status);

  /// The field.
  final String fieldKey;

  /// The register value.
  final Object? recorded;

  /// What the field worker found.
  final Object? found;

  /// How the two compare.
  final VarianceStatus status;
}

/// Whether an as-found value matches the register.
enum VarianceStatus {
  /// The same value after normalisation.
  match,

  /// A genuine difference.
  changed,

  /// The register had a value and the field was empty.
  missing,
}
