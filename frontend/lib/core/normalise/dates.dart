/// Parses dates and refuses to turn an identifier into a number.
final class Dates {
  /// Day-month-year unless [locale] is a US locale. [ambiguous] is set when
  /// both the day and the month could be either number. A year-first date
  /// (`2024-03-05`) is read as year, month, day in every locale.
  static DateValue? parse(String raw, {required String locale}) {
    final String trimmed = raw.trim();
    final RegExpMatch? iso = _yearFirst.firstMatch(trimmed);
    if (iso != null) {
      final int year = int.parse(iso.group(1)!);
      final int month = int.parse(iso.group(2)!);
      final int day = int.parse(iso.group(3)!);
      if (!_valid(year, month, day)) {
        return null;
      }
      return (original: raw, stored: _iso(year, month, day), ambiguous: false);
    }
    final RegExpMatch? numeric = _numeric.firstMatch(trimmed);
    if (numeric != null) {
      return _numericDate(trimmed, numeric, locale);
    }
    final RegExpMatch? named = _named.firstMatch(trimmed);
    if (named == null) {
      return null;
    }
    final int? month = _months[named.group(2)!.toLowerCase()];
    final int? day = int.tryParse(named.group(1)!);
    final int? year = _year(named.group(3)!);
    if (month == null ||
        day == null ||
        year == null ||
        !_valid(year, month, day)) {
      return null;
    }
    return (original: raw, stored: _iso(year, month, day), ambiguous: false);
  }

  /// A whole number, or the original text when a leading zero marks an
  /// identifier. Letters and mixed tokens are not numbers.
  static String? wholeNumber(String raw) {
    final String trimmed = raw.trim();
    if (RegExp(r'^0\d+$').hasMatch(trimmed)) {
      return trimmed;
    }
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return trimmed;
    }
    return null;
  }
}

/// Original phrasing, the stored ISO date, and whether the order was ambiguous.
typedef DateValue = ({String original, String stored, bool ambiguous});

final RegExp _yearFirst = RegExp(r'^(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})$');

final RegExp _numeric = RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})$');

final RegExp _named = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{2,4})$');

const Map<String, int> _months = <String, int>{
  'jan': 1,
  'january': 1,
  'feb': 2,
  'february': 2,
  'mar': 3,
  'march': 3,
  'apr': 4,
  'april': 4,
  'may': 5,
  'jun': 6,
  'june': 6,
  'jul': 7,
  'july': 7,
  'aug': 8,
  'august': 8,
  'sep': 9,
  'sept': 9,
  'september': 9,
  'oct': 10,
  'october': 10,
  'nov': 11,
  'november': 11,
  'dec': 12,
  'december': 12,
};

DateValue? _numericDate(String raw, RegExpMatch match, String locale) {
  final int first = int.parse(match.group(1)!);
  final int second = int.parse(match.group(2)!);
  final int? year = _year(match.group(3)!);
  if (year == null) {
    return null;
  }
  final bool unitedStates =
      locale.toLowerCase().startsWith('en_us') ||
      locale.toLowerCase() == 'en-us';
  final bool ambiguous = first <= 12 && second <= 12 && first != second;
  final int day = unitedStates ? second : first;
  final int month = unitedStates ? first : second;
  if (!_valid(year, month, day)) {
    return null;
  }
  return (original: raw, stored: _iso(year, month, day), ambiguous: ambiguous);
}

int? _year(String raw) {
  final int? value = int.tryParse(raw);
  if (value == null) {
    return null;
  }
  if (raw.length <= 2) {
    return value >= 70 ? 1900 + value : 2000 + value;
  }
  return value;
}

bool _valid(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return false;
  }
  final DateTime date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}

String _iso(int year, int month, int day) {
  final String y = year.toString().padLeft(4, '0');
  final String m = month.toString().padLeft(2, '0');
  final String d = day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
