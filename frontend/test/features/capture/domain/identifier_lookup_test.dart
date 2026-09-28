import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/identifier_lookup.dart';

/// Task 012 budget: a lookup over 10,000 records stays under 300 ms
/// (FE-PERF-06, FE-TEST-09).
const Duration _lookupBudget = Duration(milliseconds: 300);

void main() {
  test('one project record with the identifier resolves to that record', () {
    final IdentifierMatch match = IdentifierLookup.resolve(
      identifier: 'A-1',
      recordIds: <String>['r1'],
    );

    expect(match.kind, IdentifierOutcomeKind.record);
    expect(match.recordIds, <String>['r1']);
    expect(match.referenceKey, isNull);
    expect(match.label, 'A-1');
  });

  test('a reference row matches when no record does', () {
    final IdentifierMatch match = IdentifierLookup.resolve(
      identifier: 'A-1',
      recordIds: const <String>[],
      referenceKey: 'row-9',
      referenceLabel: 'Pump 9',
    );

    expect(match.kind, IdentifierOutcomeKind.reference);
    expect(match.referenceKey, 'row-9');
    expect(match.label, 'Pump 9');
    expect(match.recordIds, isEmpty);
  });

  test('a reference match without a label shows the identifier', () {
    final IdentifierMatch match = IdentifierLookup.resolve(
      identifier: 'A-1',
      recordIds: const <String>[],
      referenceKey: 'row-9',
    );

    expect(match.label, 'A-1');
  });

  test('nothing matched offers a new record with the identifier filled', () {
    final IdentifierMatch match = IdentifierLookup.resolve(
      identifier: 'A-1',
      recordIds: const <String>[],
    );

    expect(match.kind, IdentifierOutcomeKind.none);
    expect(match.label, 'A-1');
    expect(match.recordIds, isEmpty);
    expect(match.referenceKey, isNull);
  });

  test('two records sharing the identifier are listed, not guessed', () {
    final IdentifierMatch match = IdentifierLookup.resolve(
      identifier: 'A-1',
      recordIds: <String>['r1', 'r2'],
      referenceKey: 'row-9',
    );

    expect(match.kind, IdentifierOutcomeKind.duplicates);
    expect(match.recordIds, <String>['r1', 'r2']);
    expect(match.referenceKey, isNull);
  });

  test('a record match wins over a reference match', () {
    final IdentifierMatch match = IdentifierLookup.resolve(
      identifier: 'A-1',
      recordIds: <String>['r1'],
      referenceKey: 'row-9',
      referenceLabel: 'Pump 9',
    );

    expect(match.kind, IdentifierOutcomeKind.record);
    expect(match.label, 'A-1');
  });

  test('an empty reference key is no match', () {
    final IdentifierMatch match = IdentifierLookup.resolve(
      identifier: 'A-1',
      recordIds: const <String>[],
      referenceKey: '',
    );

    expect(match.kind, IdentifierOutcomeKind.none);
  });

  test('a blank identifier resolves to nothing even with records fetched', () {
    final IdentifierMatch match = IdentifierLookup.resolve(
      identifier: '   ',
      recordIds: <String>['r1', 'r2'],
      referenceKey: 'row-9',
    );

    expect(match.kind, IdentifierOutcomeKind.none);
    expect(match.recordIds, isEmpty);
    expect(match.label, '');
  });

  test('the identifier is trimmed and otherwise carried as data', () {
    const String scanned = '  "A-1"; DROP TABLE records --  ';

    final IdentifierMatch match = IdentifierLookup.resolve(
      identifier: scanned,
      recordIds: const <String>[],
    );

    expect(match.label, scanned.trim());
  });

  test('resolving against ten thousand matches stays inside the 300 ms lookup '
      'budget', () {
    final List<String> records = <String>[
      for (var i = 0; i < 10000; i++) 'record-$i',
    ];
    final Stopwatch clock = Stopwatch()..start();

    final IdentifierMatch match = IdentifierLookup.resolve(
      identifier: 'A-1',
      recordIds: records,
    );
    clock.stop();

    expect(match.kind, IdentifierOutcomeKind.duplicates);
    expect(match.recordIds, hasLength(10000));
    expect(clock.elapsed, lessThan(_lookupBudget));
  });
}
