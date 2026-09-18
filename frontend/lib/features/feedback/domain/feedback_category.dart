/// What kind of feedback an entry is.
///
/// [wireName] is what is stored; [exportLabel] is what a workbook shows.
/// Both are file-format values that stay put when the interface is
/// translated, so an old export and a new one still filter the same way.
enum FeedbackCategory {
  /// Anything that is not one of the others.
  general('general', 'General feedback'),

  /// Something that works but could work better. No longer offered on the
  /// form; kept so entries saved with it still read, filter and export.
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

  /// The types the form offers, in the order it shows them.
  static const List<FeedbackCategory> offered = <FeedbackCategory>[
    general,
    error,
    suggestion,
    other,
  ];

  /// The types a filter offers: those the form offers, plus any retired
  /// type that [stored] still holds, so old entries can still be found.
  static List<FeedbackCategory> filterable(Iterable<FeedbackCategory> stored) {
    final Set<FeedbackCategory> present = stored.toSet();
    return <FeedbackCategory>[
      for (final FeedbackCategory category in values)
        if (offered.contains(category) || present.contains(category)) category,
    ];
  }

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
