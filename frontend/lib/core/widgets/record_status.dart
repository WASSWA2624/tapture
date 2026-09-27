/// One record-lifecycle status. The set is closed; export is not a status
/// (task 162). Mapped only through `StatusStyle` and `AppStatusPill`.
///
/// Pure Dart, so domain code can name a status without importing Flutter
/// (FE-STR-05). `app_status_pill.dart` re-exports it.
enum RecordStatus {
  /// Saved locally, not yet captured in the field.
  draft,

  /// Evidence is on the record; processing has not started.
  captured,

  /// Waiting for on-device or online processing.
  queued,

  /// A processing job is running.
  processing,

  /// Extraction finished; review may still be required.
  extracted,

  /// A person must look at this record.
  needsReview,

  /// A person has accepted the record.
  approved,

  /// Processing or validation failed.
  failed,

  /// Kept for history, hidden from the working list.
  archived,

  /// Marked gone; purge is a later job.
  deleted;

  /// The spelling written to `records.status`: the enum name, so
  /// `needsReview` is stored as `needsReview` (task 014 D2).
  String get stored => name;

  /// The status stored as [raw], folding case and `_` so legacy spellings
  /// (`NEEDS_REVIEW`, `needs_review`, `CAPTURED`) still read; null when [raw]
  /// names no status.
  static RecordStatus? fromStored(String raw) {
    final String folded = raw.replaceAll('_', '').toLowerCase();
    for (final RecordStatus status in RecordStatus.values) {
      if (status.name.toLowerCase() == folded) {
        return status;
      }
    }
    return null;
  }
}
