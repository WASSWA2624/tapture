/// What one line of a record's history is about (task 014 step 6).
///
/// History is read from the local audit table. The audit action set stays
/// `created`/`updated`/`deleted` (audit rows travel in bundles, D10), so the
/// kind is told apart by [classify] from the row's entity, field key, new
/// value and reason.
enum RecordHistoryKind {
  /// The record was captured, imported or saved by hand.
  created,

  /// A field value was written or corrected.
  valueChanged,

  /// The status moved: approval, archive, delete, restore and the rest.
  statusChanged,

  /// A photo was added to the record.
  photoAdded,

  /// A photo was removed from the record.
  photoRemoved,

  /// A record or photo caption was written or corrected.
  captionChanged,

  /// The record was moved to another template.
  templateChanged,

  /// A processing run completed or failed.
  processed,

  /// The record arrived or changed through a merge.
  merged,

  /// The record was included in an export.
  exported,

  /// A value lost, or got back, every photo it was read from.
  evidenceRemoved,

  /// A value was retired by a template change, or mapped again.
  retired,

  /// Anything else the audit table holds for the record.
  other;

  /// The kind of an audit row, by the D10 conventions.
  ///
  /// [entityType] is the audited table (`records`, `photos`, `captions`),
  /// [action] the stored audit action. On `records`, [fieldKey] is either a
  /// value's field key or one of the record-level markers `status`,
  /// `templateId`, `photo` (new value `added`/`removed`), `processing`,
  /// `export` and `merge`. A flag row carries the value's field key with
  /// [reason] `evidenceRemoved` or `retired`.
  static RecordHistoryKind classify({
    required String entityType,
    required String action,
    String? fieldKey,
    String? newValue,
    String? reason,
  }) {
    if (entityType == _captions) {
      return captionChanged;
    }
    if (entityType == _photos) {
      return switch (action) {
        _created => photoAdded,
        _deleted => photoRemoved,
        _ => other,
      };
    }
    if (reason == _evidenceRemoved) {
      return evidenceRemoved;
    }
    if (reason == _retired) {
      return retired;
    }
    final String? marker = fieldKey;
    if (marker == null || marker.isEmpty) {
      return action == _created ? created : other;
    }
    return switch (marker) {
      _status => statusChanged,
      _templateId => templateChanged,
      _photo => newValue == _removed ? photoRemoved : photoAdded,
      _processing => processed,
      _export => exported,
      _merge => merged,
      _templateRowId || _evidenceMissing => other,
      _ => valueChanged,
    };
  }
}

const String _captions = 'captions';
const String _photos = 'photos';
const String _created = 'created';
const String _deleted = 'deleted';
const String _status = 'status';
const String _templateId = 'templateId';
const String _templateRowId = 'templateRowId';
const String _photo = 'photo';
const String _removed = 'removed';
const String _processing = 'processing';
const String _export = 'export';
const String _merge = 'merge';
const String _evidenceRemoved = 'evidenceRemoved';
const String _evidenceMissing = 'evidenceMissing';
const String _retired = 'retired';
