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
    final Map<String, FieldSchema> known = <String, FieldSchema>{
      for (final FieldSchema field in schema) field.key: field,
    };
    final Object? fieldsRaw = decoded['fields'];
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
    final Object? matched = decoded['matched_row'];
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
    final ({bool valid, String? value}) coerced = _coerce(raw, schema);
    if (!coerced.valid) {
      return null;
    }
    // A bare value carries no score and no evidence, so it is never trusted
    // above review.
    return (
      key: key,
      value: coerced.value,
      confidence: 0,
      evidence: const <String>[],
    );
  }
  if (raw is! Map) {
    return null;
  }
  if (!raw.containsKey('value')) {
    return null;
  }
  final Object? value = raw['value'];
  if (value != null && value is! String && value is! num && value is! bool) {
    return null;
  }
  final Object? confidence = raw['confidence'];
  if (confidence != null && confidence is! num) {
    return null;
  }
  final double score = confidence is num ? confidence.toDouble() : 0;
  if (!score.isFinite || score < 0 || score > 1) {
    return null;
  }
  final Object? evidence = raw['evidence'];
  final List<String> links = <String>[];
  if (evidence != null && evidence is! List) {
    return null;
  }
  if (evidence is List<Object?>) {
    for (final Object? item in evidence) {
      if (item is! String) {
        return null;
      }
      links.add(item);
    }
  }
  if (value == null) {
    return (key: key, value: null, confidence: score, evidence: links);
  }
  final ({bool valid, String? value}) coerced = _coerce(value, schema);
  if (!coerced.valid) {
    return null;
  }
  return (key: key, value: coerced.value, confidence: score, evidence: links);
}

({bool valid, String? value}) _coerce(Object value, FieldSchema schema) {
  final String type = schema.type.toLowerCase();
  final String text = value.toString().trim();
  if (type == 'number' || type == 'decimal') {
    if (value is bool || text.isEmpty) {
      return (valid: false, value: null);
    }
    final double? number = double.tryParse(text);
    if (number == null || !number.isFinite) {
      return (valid: false, value: null);
    }
    if (type == 'number') {
      if (number != number.roundToDouble()) {
        return (valid: false, value: null);
      }
      return (valid: true, value: number.round().toString());
    }
    return (valid: true, value: text);
  }
  if (type == 'boolean' || type == 'bool') {
    if (value is bool) {
      return (valid: true, value: value ? 'true' : 'false');
    }
    final String folded = text.toLowerCase();
    if (folded != 'true' && folded != 'false') {
      return (valid: false, value: null);
    }
    return (valid: true, value: folded);
  }
  if (value is bool && type != 'text' && type != 'string') {
    return (valid: false, value: null);
  }
  return (valid: true, value: text);
}
