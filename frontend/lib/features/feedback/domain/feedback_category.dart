/// What kind of feedback an entry is.
///
/// [wireName] is what is stored; [exportLabel] is what a workbook shows.
/// Both are file-format values that stay put when the interface is
/// translated, so an old export and a new one still filter the same way.
enum FeedbackCategory {
  /// Anything that is not one of the others.
  general('general', 'General feedback'),

  /// Something that works but could work better.
  improvement('improvement', 'Improvement'),

  /// Something is wrong.
  error('error', 'Error in the app'),

  /// An idea.
  suggestion('suggestion', 'Suggestion'),

  /// A kind the operator names themselves.
  other('other', 'Other');

  const FeedbackCategory(this.wireName, this.exportLabel);

  /// Stored name. Never renamed.
  final String wireName;

  /// Name in an exported workbook.
  final String exportLabel;

  /// The category stored as [name], or [general] for a name this build does
  /// not know.
  static FeedbackCategory fromWire(Object? name) {
    for (final FeedbackCategory category in values) {
      if (category.wireName == name) {
        return category;
      }
    }
    return general;
  }
}
