/// What an override, a link or a merge writes, so the domain stays free of
/// Drift (task 015). A person has already chosen; this only records it.
abstract interface class DuplicateLedger {
  /// Replaces [fieldKey], keeping [previous] in the history beside [next].
  void replaceValue({
    required String fieldKey,
    required String? previous,
    required String next,
  });

  /// Attaches a photo that lived on the other record.
  void attachPhoto(String sha256);

  /// Appends an audit row naming the choice, both records and the person.
  void addAudit({
    required String action,
    required String leftId,
    required String rightId,
    required String person,
    required String detail,
  });
}
