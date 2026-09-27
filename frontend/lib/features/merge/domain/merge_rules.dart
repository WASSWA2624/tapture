import 'settlement_rule.dart';

/// The four automatic rules, in order. Anything else is a conflict.
final class MergeRules {
  /// Creates the rules.
  const MergeRules();

  /// The first rule that decides, or [SettlementRule.none].
  SettlementRule settle(FieldSide mine, FieldSide theirs) {
    if (mine.verified != theirs.verified) {
      return SettlementRule.verifiedBeatsUnverified;
    }
    if (mine.scanned != theirs.scanned) {
      return SettlementRule.scannedBeatsInferred;
    }
    if (mine.edited != theirs.edited &&
        (mine.value.isEmpty || theirs.value.isEmpty)) {
      return SettlementRule.valueBeatsUntouchedEmpty;
    }
    return SettlementRule.none;
  }
}

/// One side of a differing field.
typedef FieldSide = ({String value, bool verified, bool scanned, bool edited});
