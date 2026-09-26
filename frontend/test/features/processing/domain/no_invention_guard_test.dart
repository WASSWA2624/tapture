import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/no_invention_guard.dart';

void main() {
  test('a supported value within pattern and options is kept', () {
    final GuardOutcome kept = NoInventionGuard.check(
      fieldKey: 'serial',
      value: 'SN458923',
      evidence: const <String>['photo-1'],
      evidenceRequired: true,
      pattern: r'SN\d{6}',
    );
    expect(kept.value, 'SN458923');
    expect(kept.rejection, isNull);
  });

  test('an unsupported value is dropped with its reason', () {
    final GuardOutcome dropped = NoInventionGuard.check(
      fieldKey: 'purchase_year',
      value: '2019',
      evidence: const <String>[],
      evidenceRequired: true,
    );
    expect(dropped.value, isNull);
    expect(dropped.rejection?.fieldKey, 'purchase_year');
    expect(dropped.rejection?.reason, 'No evidence supports purchase_year.');
  });

  test('a value that breaks the identifier pattern is dropped', () {
    final GuardOutcome dropped = NoInventionGuard.check(
      fieldKey: 'serial',
      value: 'SN45',
      evidence: const <String>['photo-1'],
      evidenceRequired: false,
      pattern: r'SN\d{6}',
    );
    expect(dropped.value, isNull);
    expect(
      dropped.rejection?.reason,
      'serial does not match its identifier pattern.',
    );
  });

  test('a partial pattern match is not a match', () {
    final GuardOutcome dropped = NoInventionGuard.check(
      fieldKey: 'serial',
      value: 'XSN458923',
      evidence: const <String>['photo-1'],
      evidenceRequired: false,
      pattern: r'SN\d{6}',
    );
    expect(dropped.value, isNull);
  });

  test('an off-list option is dropped', () {
    final GuardOutcome dropped = NoInventionGuard.check(
      fieldKey: 'condition',
      value: 'Excellent',
      evidence: const <String>['photo-1'],
      evidenceRequired: false,
      options: const <String>['Good', 'Faulty'],
    );
    expect(dropped.value, isNull);
    expect(
      dropped.rejection?.reason,
      'condition is not one of the allowed options.',
    );
    expect(
      NoInventionGuard.check(
        fieldKey: 'condition',
        value: 'faulty',
        evidence: const <String>['photo-1'],
        evidenceRequired: false,
        options: const <String>['Good', 'Faulty'],
      ).value,
      'faulty',
    );
  });

  test('a null value is no value and no rejection', () {
    final GuardOutcome none = NoInventionGuard.check(
      fieldKey: 'purchase_year',
      value: null,
      evidence: const <String>[],
      evidenceRequired: true,
    );
    expect(none.value, isNull);
    expect(none.rejection, isNull);
  });

  test('a pattern that cannot be read drops the value', () {
    final GuardOutcome dropped = NoInventionGuard.check(
      fieldKey: 'serial',
      value: 'SN1',
      evidence: const <String>['photo-1'],
      evidenceRequired: false,
      pattern: '(',
    );
    expect(dropped.value, isNull);
    expect(dropped.rejection?.reason, contains('cannot be read'));
  });
}
