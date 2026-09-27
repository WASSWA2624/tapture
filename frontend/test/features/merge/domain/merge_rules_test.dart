import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/merge_rules.dart';
import 'package:tapture/features/merge/domain/settlement_rule.dart';

void main() {
  const MergeRules rules = MergeRules();

  test('each rule decides in order and the rest is a conflict', () {
    expect(
      rules.settle(
        (value: 'a', verified: true, scanned: false, edited: true),
        (value: 'b', verified: false, scanned: true, edited: true),
      ),
      SettlementRule.verifiedBeatsUnverified,
    );
    expect(
      rules.settle(
        (value: 'a', verified: false, scanned: true, edited: true),
        (value: 'b', verified: false, scanned: false, edited: true),
      ),
      SettlementRule.scannedBeatsInferred,
    );
    expect(
      rules.settle(
        (value: 'a', verified: false, scanned: false, edited: true),
        (value: '', verified: false, scanned: false, edited: false),
      ),
      SettlementRule.valueBeatsUntouchedEmpty,
    );
    expect(
      rules.settle(
        (value: 'a', verified: false, scanned: false, edited: true),
        (value: 'b', verified: false, scanned: false, edited: true),
      ),
      SettlementRule.none,
    );
  });
}
