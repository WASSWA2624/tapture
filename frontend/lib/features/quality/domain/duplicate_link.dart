import 'duplicate_ledger.dart';

/// Keeps both records and records that they are the same thing (task 015).
///
/// Each record can then show a badge that links to the other. Nothing is
/// overwritten.
abstract final class DuplicateLink {
  /// The ordered pair, so one relationship is stored once.
  static ({String left, String right}) pair(String a, String b) {
    return a.compareTo(b) <= 0 ? (left: a, right: b) : (left: b, right: a);
  }

  /// Writes the link's audit row, naming the ordered pair so a link is
  /// audited the same whichever way round it was given. Both records stay.
  static void keepBoth({
    required DuplicateLedger ledger,
    required String a,
    required String b,
    required String person,
  }) {
    final ({String left, String right}) ordered = pair(a, b);
    ledger.addAudit(
      action: 'link',
      leftId: ordered.left,
      rightId: ordered.right,
      person: person,
      detail: 'keep both',
    );
  }
}
