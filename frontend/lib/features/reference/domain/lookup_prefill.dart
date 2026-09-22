/// Applies a lookup fill mapping onto existing field values.
///
/// Skips any field already marked verified. Never invents values outside
/// [fillMapping]. Provenance carries the dataset row id for each write.
abstract final class LookupPrefill {
  /// Returns the updated field map. Verified entries are left untouched.
  static Map<String, PrefillField> apply({
    required Map<String, PrefillField> current,
    required Map<String, String> fillMapping,
    required Map<String, String> rowValues,
    required String rowId,
  }) {
    final Map<String, PrefillField> next = Map<String, PrefillField>.of(
      current,
    );
    for (final MapEntry<String, String> entry in fillMapping.entries) {
      final String datasetColumn = entry.key;
      final String fieldKey = entry.value;
      final PrefillField? existing = next[fieldKey];
      if (existing != null && existing.verified) {
        continue;
      }
      final String value = rowValues[datasetColumn] ?? '';
      next[fieldKey] = (
        value: value,
        verified: false,
        source: PrefillSource.lookup,
        rowId: rowId,
        linked: true,
      );
    }
    return next;
  }
}

/// One field's prefill state, kept free of Flutter and Drift.
typedef PrefillField = ({
  String value,
  bool verified,
  PrefillSource source,
  String? rowId,
  bool linked,
});

/// Where a [PrefillField] came from.
enum PrefillSource {
  /// Typed or corrected by a person.
  manual,

  /// Filled from a reference dataset.
  lookup,
}
