/// What verification mode writes onto a new record (task 015).
///
/// The register values stay in [asRecorded]. [asFound] starts as a copy, so
/// editing what the field worker found never overwrites the register.
final class VerificationPrefill {
  /// Creates a prefill.
  const VerificationPrefill({
    required this.asRecorded,
    required this.asFound,
    required this.onRegister,
  });

  /// Values taken from the register, kept apart from later edits.
  final Map<String, String> asRecorded;

  /// Values the form starts with. Edits land here.
  final Map<String, String> asFound;

  /// Whether the identifier matched a register row.
  final bool onRegister;

  /// Fills mapped fields from [row] through [binding] (field key to column).
  ///
  /// An empty row, or an identifier with no row, is not on the register and
  /// still returns a prefill so capture can continue.
  static VerificationPrefill fromRow({
    required Map<String, String>? row,
    required Map<String, String> binding,
  }) {
    if (row == null || row.isEmpty) {
      return const VerificationPrefill(
        asRecorded: <String, String>{},
        asFound: <String, String>{},
        onRegister: false,
      );
    }
    final Map<String, String> recorded = <String, String>{};
    for (final MapEntry<String, String> entry in binding.entries) {
      final String? cell = row[entry.value];
      if (cell != null && cell.trim().isNotEmpty) {
        recorded[entry.key] = cell;
      }
    }
    return VerificationPrefill(
      asRecorded: Map<String, String>.unmodifiable(recorded),
      asFound: Map<String, String>.unmodifiable(recorded),
      onRegister: true,
    );
  }
}
