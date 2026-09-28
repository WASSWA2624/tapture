import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/quality.dart';

import '../../../support/fakes/fake_duplicate_ledger.dart';

void main() {
  test(
    'override keeps the replaced value in history and writes an audit row',
    () {
      final FakeDuplicateLedger ledger = FakeDuplicateLedger();
      DuplicateOverride.apply(
        ledger: ledger,
        leftId: 'old',
        rightId: 'new',
        person: 'Ann',
        previous: const <String, String>{'serial': 'A-1'},
        next: const <String, String>{'serial': 'A-2'},
        photoHashes: const <String>['photo-1'],
      );
      expect(ledger.replacements.single.previous, 'A-1');
      expect(ledger.replacements.single.next, 'A-2');
      expect(ledger.photos, <String>['photo-1']);
      expect(ledger.audits.single.action, 'override');
      expect(ledger.audits.single.person, 'Ann');
    },
  );

  test('a value that did not change is not rewritten', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    DuplicateOverride.apply(
      ledger: ledger,
      leftId: 'old',
      rightId: 'new',
      person: 'Ann',
      previous: const <String, String>{'serial': 'A-1', 'note': 'Worn'},
      next: const <String, String>{'serial': 'A-1', 'note': 'New'},
      photoHashes: const <String>[],
    );
    expect(ledger.replacements.single.fieldKey, 'note');
    expect(ledger.replacements.single.previous, 'Worn');
    expect(ledger.replacements.single.next, 'New');
  });

  test('a field the existing record never held is replaced from nothing', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    DuplicateOverride.apply(
      ledger: ledger,
      leftId: 'old',
      rightId: 'new',
      person: 'Ann',
      previous: const <String, String>{},
      next: const <String, String>{'note': 'New'},
      photoHashes: const <String>[],
    );
    expect(ledger.replacements.single, (
      fieldKey: 'note',
      previous: null,
      next: 'New',
    ));
  });

  test('every photo of the new record is attached to the existing one', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    DuplicateOverride.apply(
      ledger: ledger,
      leftId: 'old',
      rightId: 'new',
      person: 'Ann',
      previous: const <String, String>{},
      next: const <String, String>{},
      photoHashes: const <String>['sha-1', 'sha-2', 'sha-3'],
    );
    expect(ledger.photos, <String>['sha-1', 'sha-2', 'sha-3']);
  });

  test('the audit row names both records, the person and the override', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    DuplicateOverride.apply(
      ledger: ledger,
      leftId: 'old',
      rightId: 'new',
      person: 'Ann',
      previous: const <String, String>{'serial': 'A-1'},
      next: const <String, String>{'serial': 'A-2'},
      photoHashes: const <String>[],
    );
    expect(ledger.audits.single, (
      action: 'override',
      leftId: 'old',
      rightId: 'new',
      person: 'Ann',
      detail: 'override',
    ));
  });

  test('an override with nothing to change still leaves its audit row', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    DuplicateOverride.apply(
      ledger: ledger,
      leftId: 'old',
      rightId: 'new',
      person: 'Ann',
      previous: const <String, String>{'serial': 'A-1'},
      next: const <String, String>{'serial': 'A-1'},
      photoHashes: const <String>[],
    );
    expect(ledger.replacements, isEmpty);
    expect(ledger.audits.single.action, 'override');
  });

  test('the previous values are read, never edited', () {
    final FakeDuplicateLedger ledger = FakeDuplicateLedger();
    final Map<String, String> previous = <String, String>{'serial': 'A-1'};
    DuplicateOverride.apply(
      ledger: ledger,
      leftId: 'old',
      rightId: 'new',
      person: 'Ann',
      previous: previous,
      next: const <String, String>{'serial': 'A-2', 'note': 'New'},
      photoHashes: const <String>[],
    );
    expect(previous, <String, String>{'serial': 'A-1'});
    expect(ledger.replacements, hasLength(2));
  });
}
