import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/normalise/dates.dart';

void main() {
  test('day-month-year is read with the project locale', () {
    final DateValue? uk = Dates.parse('25/03/2024', locale: 'en_GB');
    expect(uk?.stored, '2024-03-25');
    expect(uk?.ambiguous, isFalse);
    expect(uk?.original, '25/03/2024');
  });

  test('an ambiguous date follows the locale and says so', () {
    final DateValue? uk = Dates.parse('05/03/2024', locale: 'en_GB');
    final DateValue? us = Dates.parse('05/03/2024', locale: 'en_US');
    expect(uk?.stored, '2024-03-05');
    expect(us?.stored, '2024-05-03');
    expect(uk?.ambiguous, isTrue);
    expect(us?.ambiguous, isTrue);
  });

  test('common forms are read', () {
    expect(Dates.parse('2024-03-05', locale: 'en_US')?.stored, '2024-03-05');
    expect(Dates.parse('5 March 2024', locale: 'en_GB')?.stored, '2024-03-05');
    expect(Dates.parse('05.03.24', locale: 'en_GB')?.stored, '2024-03-05');
    expect(Dates.parse('5-3-99', locale: 'en_GB')?.stored, '1999-03-05');
  });

  test('an impossible date is refused', () {
    expect(Dates.parse('31/02/2024', locale: 'en_GB'), isNull);
    expect(Dates.parse('2024-13-01', locale: 'en_GB'), isNull);
    expect(Dates.parse('no date', locale: 'en_GB'), isNull);
  });

  test('an identifier is never coerced to a number', () {
    expect(Dates.wholeNumber('0042'), '0042');
    expect(Dates.wholeNumber('42'), '42');
    expect(Dates.wholeNumber('4A2'), isNull);
    expect(Dates.wholeNumber('SN-0042'), isNull);
    expect(Dates.parse('0042', locale: 'en_GB'), isNull);
  });
}
