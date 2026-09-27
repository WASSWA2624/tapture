import 'package:tapture/core/constants/app_constants.dart';

/// The one formatter every export writer calls (task 018, FE-CONS-09).
///
/// Dates and numbers arrive already normalised. Identifiers stay text, so a
/// leading zero is never dropped. Every format receives the same string.
final class ValueFormatter {
  /// Creates a formatter. [registry] names the field types it understands.
  const ValueFormatter(this.registry);

  /// Type names this formatter renders, matching the field registry.
  final Set<String> registry;

  /// Rendered form of [value] for [type]. Null becomes the empty string.
  String format(Object? value, String type, ExportFormat target) {
    final String rendered = _text(value, type);
    return switch (target) {
      ExportFormat.xlsx ||
      ExportFormat.csv ||
      ExportFormat.json ||
      ExportFormat.pdf ||
      ExportFormat.zip => rendered,
    };
  }

  /// Native form for writers that carry cell types. Identifiers stay strings.
  Object? typed(Object? value, String type) {
    if (value == null) {
      return null;
    }
    if (_identifier(type) || value is String) {
      return _text(value, type);
    }
    if (value is DateTime && _date(type)) {
      return value;
    }
    if (value is num && _number(type)) {
      return value;
    }
    if (value is bool) {
      return value;
    }
    return _text(value, type);
  }

  String _text(Object? value, String type) {
    if (value == null) {
      return '';
    }
    if (value is List<Object?>) {
      return value
          .map((Object? part) => _text(part, type))
          .where((String part) => part.isNotEmpty)
          .join(AppConstants.exportValues.multiSeparator);
    }
    if (value is Map) {
      final Map<String, Object?> map = Map<String, Object?>.from(value);
      final String label = map['label'] as String? ?? '';
      final String code = map['code'] as String? ?? '';
      if (label.isEmpty) {
        return code;
      }
      if (code.isEmpty) {
        return label;
      }
      return '$label ($code)';
    }
    if (_identifier(type)) {
      return value.toString();
    }
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    if (value is DateTime && _date(type)) {
      final DateTime utc = value.toUtc();
      final String month = utc.month.toString().padLeft(2, '0');
      final String day = utc.day.toString().padLeft(2, '0');
      final String date = '${utc.year}-$month-$day';
      if (type == 'time') {
        final String hour = utc.hour.toString().padLeft(2, '0');
        final String minute = utc.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }
      if (type == 'dateTime') {
        final String hour = utc.hour.toString().padLeft(2, '0');
        final String minute = utc.minute.toString().padLeft(2, '0');
        return '$date $hour:$minute';
      }
      return date;
    }
    if (value is num && _number(type)) {
      return value.toString();
    }
    return value.toString();
  }

  bool _identifier(String type) {
    return type == 'barcode' || type == 'identifier' || type == 'text';
  }

  bool _date(String type) {
    return type == 'date' || type == 'time' || type == 'dateTime';
  }

  bool _number(String type) {
    return type == 'number' ||
        type == 'decimal' ||
        type == 'currency' ||
        type == 'percentage';
  }
}

/// Contract name for [ValueFormatter].
typedef ExportValueFormatter = ValueFormatter;

/// Formats a deliverable export can write (task 018).
enum ExportFormat {
  /// Workbook.
  xlsx,

  /// Comma-separated text.
  csv,

  /// Full-fidelity JSON.
  json,

  /// A report.
  pdf,

  /// A package of the other outputs.
  zip,
}
