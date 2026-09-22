/// Outcome of resolving a scanned or typed identifier.
enum IdentifierOutcomeKind {
  /// One project record matched.
  record,

  /// One reference-dataset row matched.
  reference,

  /// Nothing matched — offer a new record.
  none,

  /// Several project records share the identifier.
  duplicates,
}

/// One lookup result the operator can act on in a single tap.
final class IdentifierMatch {
  /// Creates a match.
  const IdentifierMatch({
    required this.kind,
    this.recordIds = const <String>[],
    this.referenceKey,
    this.label = '',
  });

  /// Which outcome this is.
  final IdentifierOutcomeKind kind;

  /// Matching record ids (one or many).
  final List<String> recordIds;

  /// Reference row key when [kind] is reference.
  final String? referenceKey;

  /// Display label.
  final String label;
}

/// Resolves an identifier against project records then reference data.
abstract final class IdentifierLookup {
  /// Picks the outcome from pre-fetched [recordIds] and optional
  /// [referenceKey]. The identifier is never interpolated into a path
  /// (FE-SEC-05).
  static IdentifierMatch resolve({
    required String identifier,
    required List<String> recordIds,
    String? referenceKey,
    String? referenceLabel,
  }) {
    final String quoted = identifier.trim();
    if (quoted.isEmpty) {
      return const IdentifierMatch(kind: IdentifierOutcomeKind.none);
    }
    if (recordIds.length > 1) {
      return IdentifierMatch(
        kind: IdentifierOutcomeKind.duplicates,
        recordIds: recordIds,
        label: quoted,
      );
    }
    if (recordIds.length == 1) {
      return IdentifierMatch(
        kind: IdentifierOutcomeKind.record,
        recordIds: recordIds,
        label: quoted,
      );
    }
    if (referenceKey != null && referenceKey.isNotEmpty) {
      return IdentifierMatch(
        kind: IdentifierOutcomeKind.reference,
        referenceKey: referenceKey,
        label: referenceLabel ?? quoted,
      );
    }
    return IdentifierMatch(kind: IdentifierOutcomeKind.none, label: quoted);
  }
}
