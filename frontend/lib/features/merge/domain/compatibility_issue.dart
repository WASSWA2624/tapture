/// One way an incoming template differs from the local one it would merge
/// into (task 076, D15). A blocker stops the merge; a difference only warns
/// (FE-SIMP-08).
enum CompatibilityIssue {
  /// No local template has this template's id or stable key. Blocks.
  noMatch(blocks: true),

  /// A field that holds incoming values does not exist locally. Blocks.
  missingField(blocks: true),

  /// A field that holds incoming values has a local type that cannot hold
  /// them. Blocks.
  typeCannotHold(blocks: true),

  /// The two sides are different versions of the template.
  otherVersion(blocks: false),

  /// The local template has fields the incoming one lacks.
  localOnlyFields(blocks: false),

  /// A field is required on one side and not on the other.
  changedRequiredness(blocks: false),

  /// A field has another label on each side.
  changedLabel(blocks: false),

  /// A field has another type on each side, and the local one holds the
  /// incoming values.
  changedType(blocks: false),

  /// An incoming field no record fills is missing locally.
  unfilledMissing(blocks: false);

  const CompatibilityIssue({required this.blocks});

  /// Whether this issue stops the merge.
  final bool blocks;
}
