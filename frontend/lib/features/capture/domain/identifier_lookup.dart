import 'identifier_match.dart';

export 'identifier_match.dart';

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
