/// Parses a value and a unit, then converts to the field's unit.
///
/// The original phrasing is kept beside the stored value.
final class Units {
  /// [targetUnit] is the unit configured on the field, for example `L`.
  static UnitValue? convert(String raw, {required String targetUnit}) {
    final RegExpMatch? match = _value.firstMatch(raw.trim());
    if (match == null) {
      return null;
    }
    final String amount = match.group(1)!;
    final String? unitWord = match.group(2);
    final String? sourceUnit = unitWord == null
        ? targetUnit
        : _canonical(unitWord);
    final String? target = _canonical(targetUnit);
    if (sourceUnit == null || target == null) {
      return null;
    }
    final double? converted = _convert(
      double.parse(amount),
      from: sourceUnit,
      to: target,
    );
    if (converted == null) {
      return null;
    }
    return (original: raw, stored: '${_number(converted)} $target');
  }
}

/// Original phrasing and the value stored in the field's unit.
typedef UnitValue = ({String original, String stored});

final RegExp _value = RegExp(r'^(\d+(?:\.\d+)?)\s*([A-Za-z]+)?(?:\s+.+)?$');

String? _canonical(String word) {
  switch (word.toLowerCase()) {
    case 'l':
    case 'litre':
    case 'litres':
    case 'liter':
    case 'liters':
      return 'L';
    case 'v':
    case 'volt':
    case 'volts':
      return 'V';
    case 'kg':
    case 'kilogram':
    case 'kilograms':
      return 'kg';
    case 'g':
    case 'gram':
    case 'grams':
      return 'g';
    case 'ml':
    case 'millilitre':
    case 'millilitres':
      return 'mL';
    case 'mm':
    case 'millimetre':
    case 'millimetres':
    case 'millimeter':
    case 'millimeters':
      return 'mm';
    case 'cm':
    case 'centimetre':
    case 'centimetres':
    case 'centimeter':
    case 'centimeters':
      return 'cm';
    case 'm':
    case 'metre':
    case 'metres':
    case 'meter':
    case 'meters':
      return 'm';
    default:
      return null;
  }
}

double? _convert(double value, {required String from, required String to}) {
  if (from == to) {
    return value;
  }
  const Map<String, ({String family, double base})> units =
      <String, ({String family, double base})>{
        'mL': (family: 'volume', base: 0.001),
        'L': (family: 'volume', base: 1),
        'g': (family: 'mass', base: 0.001),
        'kg': (family: 'mass', base: 1),
        'mm': (family: 'length', base: 0.001),
        'cm': (family: 'length', base: 0.01),
        'm': (family: 'length', base: 1),
        'V': (family: 'voltage', base: 1),
      };
  final ({String family, double base})? source = units[from];
  final ({String family, double base})? target = units[to];
  if (source == null || target == null || source.family != target.family) {
    return null;
  }
  return value * source.base / target.base;
}

String _number(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
