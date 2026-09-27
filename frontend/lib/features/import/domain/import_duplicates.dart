/// Applies one match decision, including a choice saved for the rest of the run.
final class ImportDuplicates {
  /// The outcome for one row. [ask] means a person still has to choose.
  static ImportMatch apply({
    required bool matched,
    ImportDuplicateChoice? choice,
    ImportDuplicateChoice? applyToAll,
  }) {
    if (!matched) {
      return ImportMatch.create;
    }
    final ImportDuplicateChoice? decided = choice ?? applyToAll;
    return switch (decided) {
      null => ImportMatch.ask,
      ImportDuplicateChoice.keepExisting => ImportMatch.keep,
      ImportDuplicateChoice.replace => ImportMatch.replace,
      ImportDuplicateChoice.merge => ImportMatch.merge,
    };
  }
}

/// How one matched or new row is handled.
enum ImportMatch {
  /// No existing record, so the row is new.
  create,

  /// The existing record stays.
  keep,

  /// The row replaces the existing record.
  replace,

  /// Empty fields on the existing record take the row.
  merge,

  /// A person still has to choose.
  ask,
}

/// What an import does with a row that matches a record already here.
///
/// This is not data quality's duplicate choice. Similarity stays there.
enum ImportDuplicateChoice {
  /// Leave the existing record as it is.
  keepExisting,

  /// Replace the existing values with the row.
  replace,

  /// Keep both sides' values, incoming filling only empty fields.
  merge,
}
