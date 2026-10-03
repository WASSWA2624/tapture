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
