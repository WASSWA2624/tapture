import 'package:tapture/core/constants/app_constants.dart';

/// Proposes a field type, unit and option list for each column.
///
/// Every result is a suggestion with no authority of its own. Types are the
/// wire names declared in the field type registry (`number`, `choice`, …).
abstract final class TypeInference {
  /// Infers one suggestion per header from [sampleRows] under that header.
  static List<ColumnSuggestion> suggest({
    required List<String> headers,
    required List<List<String>> sampleRows,
  }) {
    return <ColumnSuggestion>[
      for (int index = 0; index < headers.length; index++)
        _column(header: headers[index], samples: _samples(sampleRows, index)),
    ];
  }
}

/// One proposed column: registry [typeName], optional [unit] and [options].
///
/// [isSuggestion] is always true — the caller must let the operator edit it.
typedef ColumnSuggestion = ({
  String header,
  String typeName,
  String? unit,
  List<String> options,
  bool isSuggestion,
});

ColumnSuggestion _column({
  required String header,
  required List<String> samples,
}) {
  final String typeName = _typeOf(samples);
  return (
    header: header,
    typeName: typeName,
    unit: _unitOf(header, samples),
    options: typeName == _choice
        ? (samples.map((String v) => v.trim()).toSet().toList()..sort())
        : const <String>[],
    isSuggestion: true,
  );
}

List<String> _samples(List<List<String>> rows, int index) {
  return <String>[
    for (final List<String> row in rows)
      if (index < row.length && row[index].trim().isNotEmpty) row[index].trim(),
  ];
}

String _typeOf(List<String> samples) {
  if (samples.isEmpty) {
    return _text;
  }
  if (samples.every(_isBoolean)) {
    return _boolean;
  }
  if (samples.every(_isPercentage)) {
    return _percentage;
  }
  if (samples.every(_isCurrency)) {
    return _currency;
  }
  if (samples.every(_isDateTime)) {
    return _dateTime;
  }
  if (samples.every(_isDate)) {
    return _date;
  }
  if (samples.every(_isTime)) {
    return _time;
  }
  if (samples.every(_isInteger)) {
    return _number;
  }
  if (samples.every(_isDecimal)) {
    return _decimal;
  }
  if (_isOptionSet(samples)) {
    return _choice;
  }
  if (samples.every(_isIdentifier)) {
    return _barcode;
  }
  if (samples.any(_isLong)) {
    return _longText;
  }
  return _text;
}

String? _unitOf(String header, List<String> samples) {
  final Match? fromHeader = _unitInHeader.firstMatch(header.trim());
  if (fromHeader != null) {
    return fromHeader.group(1);
  }
  final Set<String> units = <String>{
    for (final String sample in samples)
      if (_unitFromValue(sample) != null) _unitFromValue(sample)!,
  };
  if (units.length == 1) {
    return units.single;
  }
  return null;
}

String? _unitFromValue(String sample) {
  final Match? match = _unitSuffix.firstMatch(sample.trim());
  return match?.group(1);
}

bool _isOptionSet(List<String> samples) {
  final Set<String> unique = <String>{
    for (final String sample in samples) sample.trim(),
  };
  return unique.length >= 2 &&
      unique.length <= AppConstants.workbook.optionMax &&
      unique.length < samples.length &&
      unique.every((String value) => value.length <= 40 && !_isDecimal(value));
}

bool _isBoolean(String value) {
  return _booleans.contains(value.trim().toLowerCase());
}

bool _isPercentage(String value) {
  return _percentagePattern.hasMatch(value.trim());
}

bool _isCurrency(String value) {
  return _currencyPattern.hasMatch(value.trim());
}

bool _isDateTime(String value) {
  return _dateTimePattern.hasMatch(value.trim());
}

bool _isDate(String value) {
  final String trimmed = value.trim();
  return _isoDate.hasMatch(trimmed) || _slashDate.hasMatch(trimmed);
}

bool _isTime(String value) {
  return _timePattern.hasMatch(value.trim());
}

bool _isInteger(String value) {
  return _integerPattern.hasMatch(_stripUnit(value));
}

bool _isDecimal(String value) {
  return _decimalPattern.hasMatch(_stripUnit(value));
}

bool _isIdentifier(String value) {
  final String trimmed = value.trim();
  if (trimmed.length < AppConstants.workbook.identifierMinLength) {
    return false;
  }
  return _identifierPattern.hasMatch(trimmed);
}

bool _isLong(String value) {
  return value.contains('\n') || value.trim().length > 80;
}

String _stripUnit(String value) {
  final String trimmed = value.trim();
  final Match? match = _unitSuffix.firstMatch(trimmed);
  if (match == null) {
    return trimmed;
  }
  return trimmed.substring(0, match.start).trim();
}

const String _text = 'text';
const String _longText = 'long_text';
const String _number = 'number';
const String _decimal = 'decimal';
const String _currency = 'currency';
const String _percentage = 'percentage';
const String _date = 'date';
const String _time = 'time';
const String _dateTime = 'date_time';
const String _boolean = 'boolean';
const String _choice = 'choice';
const String _barcode = 'barcode';

const Set<String> _booleans = <String>{
  'true',
  'false',
  'yes',
  'no',
  'y',
  'n',
  '1',
  '0',
};

final RegExp _percentagePattern = RegExp(r'^-?\d+(\.\d+)?\s*%$');
final RegExp _currencyPattern = RegExp(r'^[£$€]\s?\d+(\.\d+)?$');
final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp _slashDate = RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$');
final RegExp _dateTimePattern = RegExp(
  r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(:\d{2})?$',
);
final RegExp _timePattern = RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$');
final RegExp _integerPattern = RegExp(r'^-?\d+$');
final RegExp _decimalPattern = RegExp(r'^-?\d+(\.\d+)?$');
final RegExp _identifierPattern = RegExp(r'^[A-Za-z]{1,8}-?[A-Za-z0-9]{2,}$');
final RegExp _unitInHeader = RegExp(r'\(([^)]+)\)\s*$');
final RegExp _unitSuffix = RegExp(r'\s+([A-Za-z%]{1,6})$');
