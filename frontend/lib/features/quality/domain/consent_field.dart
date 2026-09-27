/// Consent stored on a record, with who confirmed it and when.
///
/// Export of a project that requires consent omits records that lack one
/// and names them. The value is record data, not a preference.
final class ConsentField {
  /// Wire name of the field type.
  static const String typeName = 'consent';

  /// Records in [rows] that cannot be exported, by id.
  static List<String> omitted({
    required bool requiredOnProject,
    required List<ConsentRow> rows,
  }) {
    if (!requiredOnProject) {
      return const <String>[];
    }
    return <String>[
      for (final ConsentRow row in rows)
        if (row.consent == null) row.id,
    ];
  }
}

/// One record and its consent, if someone confirmed it.
typedef ConsentRow = ({String id, ConsentStamp? consent});

/// Who confirmed consent, and when.
typedef ConsentStamp = ({String by, DateTime at});
