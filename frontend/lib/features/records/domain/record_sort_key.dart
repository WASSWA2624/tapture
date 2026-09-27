/// What a records list is ordered by (task 014 step 2).
///
/// Every key sorts in the query with the record id as a tiebreak, so two
/// records with the same number, date or name keep a stable order.
enum RecordSortKey {
  /// The per-project record number.
  number,

  /// When the record was captured.
  capturedAt,

  /// The record's name, compared without case.
  name;

  /// The spelling written to JSON and settings: the enum name.
  ///
  /// Spelled through [EnumName] because the [name] value shadows the plain
  /// getter inside this enum.
  String get stored => EnumName(this).name;

  /// The key [raw] names, folding case and `_`, or null when it names none.
  static RecordSortKey? fromStored(String raw) {
    final String folded = raw.trim().replaceAll('_', '').toLowerCase();
    for (final RecordSortKey key in values) {
      if (key.stored.toLowerCase() == folded) {
        return key;
      }
    }
    return null;
  }
}
