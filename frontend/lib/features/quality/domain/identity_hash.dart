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

/// Letters and digits only, folded to lower case.
String normaliseIdentity(String value) {
  return foldSearchText(value).replaceAll(RegExp('[^a-z0-9]'), '');
}
