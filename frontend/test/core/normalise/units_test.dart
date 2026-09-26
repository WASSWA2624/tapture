import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/normalise/units.dart';

void main() {
  test('a value in another unit is converted and the phrasing kept', () {
    final UnitValue? value = Units.convert('500 ml', targetUnit: 'L');
    expect(value?.stored, '0.5 L');
    expect(value?.original, '500 ml');
  });

  test('spelled-out units and extra words are read', () {
    expect(Units.convert('5 litres of oil', targetUnit: 'L')?.stored, '5 L');
    expect(Units.convert('2 kilograms', targetUnit: 'g')?.stored, '2000 g');
    expect(Units.convert('1500mm', targetUnit: 'm')?.stored, '1.5 m');
  });

  test('a bare number takes the field unit', () {
    expect(Units.convert('240', targetUnit: 'V')?.stored, '240 V');
  });

  test('units of different kinds are not converted', () {
    expect(Units.convert('240 V', targetUnit: 'L'), isNull);
  });

  test('an unknown unit or text with no number is not guessed', () {
    expect(Units.convert('5 bar', targetUnit: 'L'), isNull);
    expect(Units.convert('about five litres', targetUnit: 'L'), isNull);
    expect(Units.convert('', targetUnit: 'L'), isNull);
  });
}
