import 'dart:convert';

/// A person's explicit confirmation, retained as record evidence.
final class ConsentStamp {
  /// Creates a stamp in UTC.
  ConsentStamp({required this.by, required DateTime at}) : at = at.toUtc();

  /// Person or device identity that confirmed consent.
  final String by;

  /// When consent was explicitly confirmed.
  final DateTime at;

  /// Record field value, with stable wire keys.
  Map<String, String> toJson() => <String, String>{
    'by': by,
    'at': at.toIso8601String(),
  };

  /// Accepts only structured, attributable consent; legacy booleans and
  /// model-generated free text never become permission to export evidence.
  static ConsentStamp? parse(Object? value) {
    Object? decoded = value;
    if (value is String) {
      try {
        decoded = jsonDecode(value);
      } on FormatException {
        return null;
      }
    }
    if (decoded is! Map) return null;
    final Object? by = decoded['by'];
    final Object? rawAt = decoded['at'];
    if (by is! String || by.trim().isEmpty || rawAt is! String) return null;
    if (!_utcTimestamp.hasMatch(rawAt)) return null;
    final DateTime? at = DateTime.tryParse(rawAt);
    if (at == null ||
        !at.isUtc ||
        !at.toIso8601String().startsWith(rawAt.substring(0, 19))) {
      return null;
    }
    return ConsentStamp(by: by, at: at);
  }

  /// Resolves the current attributable permission, including withdrawal.
  /// Model proposals cannot become consent through bulk approval alone.
  static ConsentStamp? authorized({
    required Object? raw,
    required String source,
    Object? refined,
    Object? approved,
    bool verified = false,
  }) {
    final String origin = source.trim().toLowerCase();
    if (origin != 'manual' && origin != 'typed') return null;
    if (approved != null || refined != null) {
      if (!verified) return null;
      final Object? current = approved ?? refined;
      if (origin == 'manual') return parse(current);
      // Approval may preserve an explicit captured stamp; it cannot grant a
      // new permission from text refined by a model beside that raw field.
      if (refined == null && current == raw) return parse(raw);
      return null;
    }
    return parse(raw);
  }

  static final RegExp _utcTimestamp = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z$',
  );
}
