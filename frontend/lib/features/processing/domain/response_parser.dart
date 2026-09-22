import 'dart:convert';

/// Parses a provider response against the template's field types.
///
/// Unknown keys are dropped. Types are coerced when that is safe. A document
/// that is not JSON, or a known field with a shape that cannot be read, is
/// rejected rather than guessed at.
final class ResponseParser {
  /// Parses [raw]. [schema] is the field list the template implies.
  static ParseOutcome parse(String raw, {required List<FieldSchema> schema}) {
    final Object? decoded = _decode(raw);
    if (decoded is! Map) {
      return (
        ok: false,
        error: 'The response is not a JSON object.',
        fields: const <String, ParsedField>{},
        matchedRow: null,
      );
    }
    final Map<String, Object?> body = Map<String, Object?>.from(decoded);
    final Map<String, FieldSchema> known = <String, FieldSchema>{
      for (final FieldSchema field in schema) field.key: field,
    };
    final Object? fieldsRaw = body['fields'];
    if (fieldsRaw is! Map) {
      return (
        ok: false,
        error: 'The response has no fields object.',
        fields: const <String, ParsedField>{},
        matchedRow: null,
      );
    }
    final Map<String, ParsedField> fields = <String, ParsedField>{};
    for (final MapEntry<Object?, Object?> entry in fieldsRaw.entries) {
      final String? key = entry.key?.toString();
      if (key == null || !known.containsKey(key)) {
        continue;
      }
      final ParsedField? field = _field(key, entry.value, known[key]!);
      if (field == null) {
        return (
          ok: false,
          error: 'Field $key is malformed.',
          fields: const <String, ParsedField>{},
          matchedRow: null,
        );
      }
      fields[key] = field;
    }
    final Object? matched = body['matched_row'];
    return (
      ok: true,
      error: null,
      fields: fields,
      matchedRow: matched is String ? matched : null,
    );
  }
}

/// One template field the parser will accept.
typedef FieldSchema = ({
  String key,
  String type,
  bool requiredField,
  String? pattern,
  List<String> options,
});

/// One parsed proposal. [value] is null when the provider had nothing.
typedef ParsedField = ({
  String key,
  String? value,
  double confidence,
  List<String> evidence,
});

/// Result of [ResponseParser.parse].
typedef ParseOutcome = ({
  bool ok,
  String? error,
  Map<String, ParsedField> fields,
  String? matchedRow,
});

Object? _decode(String raw) {
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

ParsedField? _field(String key, Object? raw, FieldSchema schema) {
  if (raw == null) {
    return (key: key, value: null, confidence: 0, evidence: const <String>[]);
  }
  if (raw is String || raw is num || raw is bool) {
    return (
      key: key,
      value: _coerce(raw, schema),
      confidence: 1,
      evidence: const <String>[],
    );
  }
  if (raw is! Map) {
    return null;
  }
  final Map<String, Object?> object = Map<String, Object?>.from(raw);
  if (!object.containsKey('value')) {
    return null;
  }
  final Object? value = object['value'];
  if (value != null && value is! String && value is! num && value is! bool) {
    return null;
  }
  final Object? confidence = object['confidence'];
  final double score = confidence is num ? confidence.toDouble() : 0;
  final Object? evidence = object['evidence'];
  final List<String> links = <String>[];
  if (evidence is List) {
    for (final Object? item in evidence) {
      if (item is String) {
        links.add(item);
      }
    }
  }
  return (
    key: key,
    value: value == null ? null : _coerce(value, schema),
    confidence: score,
    evidence: links,
  );
}

String? _coerce(Object value, FieldSchema schema) {
  if (value is bool) {
    return value ? 'true' : 'false';
  }
  final String text = value.toString();
  if (schema.type == 'number' || schema.type == 'decimal') {
    final double? number = double.tryParse(text);
    if (number == null) {
      return null;
    }
    if (schema.type == 'number' && number == number.roundToDouble()) {
      return number.round().toString();
    }
    return text;
  }
  return text;
}
