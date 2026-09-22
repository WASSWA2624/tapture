/// Per-record override of a context-prefilled field.
///
/// The raw value stays. The correction is a refined value beside it
/// (FE-SEC-08). Project context and other records are never inputs here.
abstract final class ContextOverride {
  /// Plan for one field. [rawValue] is the captured CONTEXT value.
  static ({
    String fieldKey,
    String rawValue,
    String refinedValue,
    bool overridden,
  })
  plan({
    required String fieldKey,
    required String rawValue,
    required String newValue,
  }) {
    return (
      fieldKey: fieldKey,
      rawValue: rawValue,
      refinedValue: newValue,
      overridden: newValue != rawValue,
    );
  }

  /// Whether a stored field has a refined value beside its raw one.
  static bool isOverridden({required String? rawValue, String? refinedValue}) {
    return refinedValue != null && refinedValue != rawValue;
  }
}
