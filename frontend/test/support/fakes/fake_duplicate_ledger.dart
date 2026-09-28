import 'package:tapture/features/quality/quality.dart' show DuplicateLedger;

/// One value replacement a ledger received.
typedef LedgerReplacement = ({String fieldKey, String? previous, String next});

/// One audit row a ledger received.
typedef LedgerAudit = ({
  String action,
  String leftId,
  String rightId,
  String person,
  String detail,
});

/// Records every write an override, a link or a merge makes, in the order
/// it was made, so a test can assert what history and audit will hold.
final class FakeDuplicateLedger implements DuplicateLedger {
  /// Every replacement, in order.
  final List<LedgerReplacement> replacements = <LedgerReplacement>[];

  /// Every attached photo hash, in order.
  final List<String> photos = <String>[];

  /// Every audit row, in order.
  final List<LedgerAudit> audits = <LedgerAudit>[];

  /// The kind of every write, in the order it arrived: `replace`, `photo`
  /// or `audit`.
  final List<String> log = <String>[];

  @override
  void replaceValue({
    required String fieldKey,
    required String? previous,
    required String next,
  }) {
    replacements.add((fieldKey: fieldKey, previous: previous, next: next));
    log.add('replace');
  }

  @override
  void attachPhoto(String sha256) {
    photos.add(sha256);
    log.add('photo');
  }

  @override
  void addAudit({
    required String action,
    required String leftId,
    required String rightId,
    required String person,
    required String detail,
  }) {
    audits.add((
      action: action,
      leftId: leftId,
      rightId: rightId,
      person: person,
      detail: detail,
    ));
    log.add('audit');
  }
}
