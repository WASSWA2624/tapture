import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/quality.dart';

import '../../../support/fakes/fake_duplicate_ledger.dart';

void main() {
  test('keeping both links the pair without overwriting a value', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    DuplicateLink.keepBoth(ledger: ledger, a: 'b', b: 'a', person: 'Ann');
    expect(ledger.replacements, isEmpty);
    expect(ledger.photos, isEmpty);
    expect(ledger.audits.single.leftId, 'a');
    expect(ledger.audits.single.rightId, 'b');
    expect(ledger.audits.single.action, 'link');
  });

  test('a pair is stored once whichever way round it is given', () {
    expect(DuplicateLink.pair('rec-1', 'rec-2'), DuplicateLink.pair('rec-2', 'rec-1'));
    expect(DuplicateLink.pair('rec-1', 'rec-2'), (left: 'rec-1', right: 'rec-2'));
  });

  test('a pair of one record with itself is that record on both sides', () {
    expect(DuplicateLink.pair('rec-1', 'rec-1'), (
      left: 'rec-1',
      right: 'rec-1',
    ));
  });

  test('the audit row names the person and the choice', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    DuplicateLink.keepBoth(
      ledger: ledger,
      a: 'rec-1',
      b: 'rec-2',
      person: 'Ann',
    );
    expect(ledger.audits.single.person, 'Ann');
    expect(ledger.audits.single.detail, 'keep both');
  });

  test('two links of the same pair audit the same ordered ids', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    DuplicateLink.keepBoth(ledger: ledger, a: 'x', b: 'y', person: 'Ann');
    DuplicateLink.keepBoth(ledger: ledger, a: 'y', b: 'x', person: 'Ben');
    expect(
      ledger.audits.map((LedgerAudit a) => (a.leftId, a.rightId)).toSet(),
      <(String, String)>{('x', 'y')},
    );
  });
}
