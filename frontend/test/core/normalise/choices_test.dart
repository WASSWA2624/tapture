import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/normalise/choices.dart';

void main() {
  const List<ChoiceOption> options = <ChoiceOption>[
    (label: 'Good', code: 'G', aliases: <String>['working']),
    (
      label: 'Faulty',
      code: 'F',
      aliases: <String>['damaged', 'requires repair'],
    ),
    (label: 'Missing', code: null, aliases: <String>[]),
  ];

  test('a descriptive sentence maps to Faulty and the sentence remains', () {
    final ChoiceMatch? match = Choices.match(
      'Gauge damaged and requires repair',
      options: options,
    );
    expect(match?.label, 'Faulty');
    expect(match?.original, 'Gauge damaged and requires repair');
  });

  test('label and code match before aliases', () {
    expect(Choices.match('missing', options: options)?.label, 'Missing');
    expect(Choices.match('g', options: options)?.label, 'Good');
    expect(Choices.match(' F ', options: options)?.label, 'Faulty');
  });

  test('an alias matches only as a whole word', () {
    expect(Choices.match('undamaged casing', options: options), isNull);
  });

  test('text matching no option is left for review, not guessed', () {
    expect(Choices.match('Excellent condition', options: options), isNull);
    expect(Choices.match('', options: options), isNull);
  });
}
