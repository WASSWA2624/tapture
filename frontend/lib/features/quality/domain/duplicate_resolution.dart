import 'duplicate_choice.dart';

/// What a person chose for one pair (task 015).
///
/// The save-time prompt, the comparison, the merge sheet and the bulk action
/// all hand one of these to the same repository call, so history, audit
/// entries and links are identical however a pair is cleared.
final class DuplicateResolution {
  /// Creates a resolution of [choice].
  const DuplicateResolution(
    this.choice, {
    this.picks = const <String, MergePick>{},
    this.carryPhotos = false,
  });

  /// The outcome a person chose.
  final DuplicateChoice choice;

  /// Per-field picks of a merge, by field key. A field with no pick keeps
  /// the existing record's value.
  final Map<String, MergePick> picks;

  /// Whether a merge files the newer record's photos on the survivor.
  final bool carryPhotos;

  /// Whether this choice may be applied to a whole group at once.
  ///
  /// An override has to pass through the comparison and a merge needs a
  /// person's pick per field, so neither is ever applied in bulk.
  static bool bulkAllowed(DuplicateChoice choice) {
    return choice == DuplicateChoice.keepBoth ||
        choice == DuplicateChoice.discardNew;
  }
}
