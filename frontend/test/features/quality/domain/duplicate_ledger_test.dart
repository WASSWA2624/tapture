import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/quality.dart';

import '../../../support/fakes/fake_duplicate_ledger.dart';

void main() {
  test('an override reaches the ledger as values, then photos, then audit', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    DuplicateOverride.apply(
      ledger: ledger,
      leftId: 'old',
      rightId: 'new',
      person: 'Ann',
      previous: const <String, String>{'serial': 'A-1', 'note': 'Worn'},
      next: const <String, String>{'serial': 'A-2', 'note': 'New'},
      photoHashes: const <String>['sha-1', 'sha-2'],
    );
    expect(ledger.log, <String>[
      'replace',
      'replace',
      'photo',
      'photo',
      'audit',
    ]);
  });

  test('a link reaches the ledger as one audit row and nothing else', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    DuplicateLink.keepBoth(ledger: ledger, a: 'old', b: 'new', person: 'Ann');
    expect(ledger.log, <String>['audit']);
    expect(ledger.replacements, isEmpty);
    expect(ledger.photos, isEmpty);
  });

  test('every audit row names the choice, both records and the person', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    DuplicateOverride.apply(
      ledger: ledger,
      leftId: 'old',
      rightId: 'new',
      person: 'Ann',
      previous: const <String, String>{},
      next: const <String, String>{},
      photoHashes: const <String>[],
    );
    DuplicateLink.keepBoth(ledger: ledger, a: 'old', b: 'new', person: 'Ben');
    expect(ledger.audits, hasLength(2));
    for (final LedgerAudit audit in ledger.audits) {
      expect(audit.action, isNotEmpty);
      expect(audit.leftId, 'old');
      expect(audit.rightId, 'new');
      expect(audit.person, isNotEmpty);
      expect(audit.detail, isNotEmpty);
    }
    expect(ledger.audits.map((LedgerAudit a) => a.person), <String>[
      'Ann',
      'Ben',
    ]);
    expect(ledger.audits.map((LedgerAudit a) => a.action), <String>[
      'override',
      'link',
    ]);
  });

  test(
    'a replaced value reaches history beside the value that replaced it',
    () {
      final FakeDuplicateLedger ledger = FakeDuplicateLedger();
      ledger.replaceValue(fieldKey: 'serial', previous: 'A-1', next: 'A-2');
      expect(ledger.replacements.single, (
        fieldKey: 'serial',
        previous: 'A-1',
        next: 'A-2',
      ));
    },
  );
}
