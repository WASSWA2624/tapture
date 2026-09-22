import 'lookup_prefill.dart';

/// Detaches one prefilled field without breaking the rest of the link group.
abstract final class LookupUnlink {
  /// Edits [fieldKey] to [newValue] and marks that field alone unlinked and
  /// manual. Sibling fields keep their lookup provenance.
  static Map<String, PrefillField> editField({
    required Map<String, PrefillField> current,
    required String fieldKey,
    required String newValue,
  }) {
    final Map<String, PrefillField> next = Map<String, PrefillField>.of(
      current,
    );
    final PrefillField? existing = next[fieldKey];
    if (existing == null) {
      next[fieldKey] = (
        value: newValue,
        verified: false,
        source: PrefillSource.manual,
        rowId: null,
        linked: false,
      );
      return next;
    }
    next[fieldKey] = (
      value: newValue,
      verified: true,
      source: PrefillSource.manual,
      rowId: null,
      linked: false,
    );
    return next;
  }
}
