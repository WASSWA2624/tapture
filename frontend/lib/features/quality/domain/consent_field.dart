import 'package:tapture/core/security/consent_stamp.dart' as consent;

/// Consent stored on a record, with who confirmed it and when.
///
/// Export of a project that requires consent omits records that lack one
/// and names them. The value is record data, not a preference.
final class ConsentField {
  /// Wire name of the field type.
  static const String typeName = 'consent';

  /// Reads explicit consent captured by the operator, never a boolean or
  /// free-text provider proposal.
  static ConsentStamp? parse(Object? value) {
    final consent.ConsentStamp? stamp = consent.ConsentStamp.parse(value);
    return stamp == null ? null : (by: stamp.by, at: stamp.at);
  }

  /// The current permission from capture or an explicit operator correction.
  static ConsentStamp? authorized({
    required Object? raw,
    required String source,
    Object? refined,
    Object? approved,
    bool verified = false,
  }) {
    final consent.ConsentStamp? stamp = consent.ConsentStamp.authorized(
      raw: raw,
      source: source,
      refined: refined,
      approved: approved,
      verified: verified,
    );
    return stamp == null ? null : (by: stamp.by, at: stamp.at);
  }

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
