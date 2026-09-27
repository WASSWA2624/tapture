/// A compatibility report in one word, shown as a status pill with an icon
/// and text, never colour alone (FE-A11Y-05).
enum CompatibilityStatus {
  /// The templates match.
  compatible,

  /// The templates match, with differences that only warn.
  compatibleWithDifferences,

  /// A template cannot take the incoming values; the merge cannot start.
  incompatible,
}
