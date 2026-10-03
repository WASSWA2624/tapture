/// The four ways a person can answer a duplicate (task 015).
///
/// A choice is only ever made by a person; nothing here has a default.
enum DuplicateChoice {
  /// Write the new values onto the existing record. Reachable only from the
  /// side-by-side comparison.
  overrideExisting,

  /// Keep both and link them.
  keepBoth,

  /// Drop the new record into the recycle bin.
  discardNew,

  /// Decide field by field.
  mergeFields,
}

/// One field in a merge, and which side a person kept.
///
/// "Mine" is the newer record, the one just captured; "theirs" is the record
/// that was already there and survives the merge.
enum MergePick {
  /// The newer record's value.
  mine,

  /// The existing record's value.
  theirs,

  /// Both values, the existing one first.
  both,
}
