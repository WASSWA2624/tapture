import 'dart:convert';

/// A template row's stable key, which lives in its detection JSON; empty
/// when the template has none. Rows are keyed by SQL column name, as a
/// project package carries them.
String templateKeyOf(Map<String, Object?> template) {
  final Object? detection = template['detection'];
  if (detection is! String || detection.isEmpty) {
    return '';
  }
  try {
    final Object? decoded = jsonDecode(detection);
    if (decoded is Map<String, Object?>) {
      final Object? key = decoded['template_key'];
      return key is String ? key : '';
    }
  } on FormatException {
    return '';
  }
  return '';
}
