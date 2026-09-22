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
    final String? canonical = unitWord == null
        ? targetUnit
        : _canonical(unitWord);
    if (canonical == null ||
        canonical.toLowerCase() != targetUnit.toLowerCase()) {
      if (unitWord != null && canonical != targetUnit) {
        return null;
      }
    }
    final String storedUnit = canonical ?? targetUnit;
    return (original: raw, stored: '$amount $storedUnit');
  }
}

/// Original phrasing and the value stored in the field's unit.
typedef UnitValue = ({String original, String stored});

final RegExp _value = RegExp(r'^(\d+(?:\.\d+)?)\s*([A-Za-z]+)?');

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
    default:
      return null;
  }
}
