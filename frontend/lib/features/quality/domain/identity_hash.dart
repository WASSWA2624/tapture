import 'dart:convert';

import 'package:tapture/core/hash/hashing_service.dart';
import 'package:tapture/core/normalise/search_text.dart';

/// The stable identity of a record, for duplicate lookup (task 015).
///
/// Case, whitespace and punctuation are folded away, so `ABB-1234` and
/// `abb 1234` are one identity. The hash is what gets stored on the record.
String identityHash(Map<String, Object?> values, List<String> identityKeys) {
  final List<String> parts = <String>[
    for (final String key in identityKeys)
      normaliseIdentity('${values[key] ?? ''}'),
  ]..sort();
  return sha256OfString(parts.join('\u001f'));
}

/// The identity hash a record stores (task 015).
///
/// [identityHash] of the record's identity values when its template names
/// identity fields and at least one of them holds a value; otherwise the
/// hash of [recordId], which no other record shares, so records with no
/// identity never collide on it.
String storedIdentityHash({
  required String recordId,
  required Map<String, Object?> values,
  required List<String> identityKeys,
}) {
  final bool anyValue = identityKeys.any(
    (String key) => normaliseIdentity('${values[key] ?? ''}').isNotEmpty,
  );
  if (!anyValue) {
    return sha256OfString(recordId);
  }
  return identityHash(values, identityKeys);
}

/// The identity field keys a template stores as JSON text, or none when
/// [json] is missing or not a list.
List<String> identityKeysOf(String? json) {
  if (json == null || json.trim().isEmpty) {
    return const <String>[];
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return const <String>[];
  }
  if (decoded is! List<Object?>) {
    return const <String>[];
  }
  return <String>[
    for (final Object? key in decoded)
      if (key != null && '$key'.trim().isNotEmpty) '$key',
  ];
}

/// Letters and digits only, folded to lower case.
String normaliseIdentity(String value) {
  return foldSearchText(value).replaceAll(RegExp('[^a-z0-9]'), '');
}
