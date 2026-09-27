/// A quality flag carried beside a record's status (spec §42, §55.2).
///
/// Flags are derived from the record's rows, never stored as a status, so a
/// record can carry several at once.
enum RecordFlag {
  /// At least one live photo is filed on the record.
  hasPhotos,

  /// An unresolved duplicate pairs the record with another.
  hasDuplicate,

  /// A merge left a conflict on the record that nobody has resolved.
  hasConflict,

  /// A value differs from what an earlier approval recorded.
  hasVariance,

  /// A value lost every photo it was read from; the value itself is kept.
  evidenceRemoved,

  /// The record arrived in a bundle from another device.
  mergedFromBundle;

  /// The spelling written to JSON and settings: the enum name.
  String get stored => name;

  /// The flag [raw] names, folding case and `_`, or null when it names none.
  ///
  /// `'HAS_PHOTOS'`, `'has_photos'` and `'hasPhotos'` all read as [hasPhotos].
  static RecordFlag? fromStored(String raw) {
    final String folded = _fold(raw);
    for (final RecordFlag flag in values) {
      if (_fold(flag.name) == folded) {
        return flag;
      }
    }
    return null;
  }
}

String _fold(String raw) => raw.trim().replaceAll('_', '').toLowerCase();
