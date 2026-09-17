part of 'converters.dart';

/// Narrows a JSON object to `Map<String, Object?>`.
///
/// `dynamic` is accepted only as the decoder input and is narrowed on the
/// next line (FE-CODE-05). A null object becomes an empty map.
final class JsonMapConverter
    implements JsonConverter<Map<String, Object?>, Object?> {
  /// Creates the converter.
  const JsonMapConverter();

  @override
  Map<String, Object?> fromJson(Object? json) {
    if (json == null) {
      return const <String, Object?>{};
    }
    if (json is! Map) {
      throw const FormatException('JSON object expected');
    }
    final Map<Object?, Object?> raw = Map<Object?, Object?>.from(json);
    return <String, Object?>{
      for (final MapEntry<Object?, Object?> entry in raw.entries)
        _stringKey(entry.key): entry.value,
    };
  }

  @override
  Object? toJson(Map<String, Object?> object) => object;
}

String _stringKey(Object? key) {
  if (key is String) {
    return key;
  }
  throw const FormatException('JSON object keys must be strings');
}
