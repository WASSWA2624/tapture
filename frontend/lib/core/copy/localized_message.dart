/// A semantic catalogue member and serializable arguments, with stable English
/// text for headless workers, logs and older clients. User content is never
/// used to discover a message key.
final class LocalizedMessage {
  /// Creates a message. [arguments] are encoded with [encodeArgument].
  const LocalizedMessage({
    required this.key,
    required this.fallback,
    this.arguments = const <String, Object?>{},
  });

  /// Retains explicit custom text without guessing a catalogue identity.
  const LocalizedMessage.literal(String text)
    : key = '',
      fallback = text,
      arguments = const <String, Object?>{};

  /// Retains optional explicit text while preserving the absence of an error.
  static LocalizedMessage? optional(String? text) =>
      text == null ? null : LocalizedMessage.literal(text);

  /// Public Copy member, independent of language and displayed text.
  final String key;

  /// JSON-safe argument values. Factories encode structured values explicitly.
  final Map<String, Object?> arguments;

  /// The original English text retained for auditing and headless operation.
  final String fallback;

  /// Retains a nested semantic argument without flattening its locale.
  LocalizedMessage withArgument(String name, Object? value) => LocalizedMessage(
    key: key,
    fallback: fallback,
    arguments: Map<String, Object?>.unmodifiable(<String, Object?>{
      ...arguments,
      name: encodeArgument(value),
    }),
  );

  @override
  bool operator ==(Object other) =>
      other is LocalizedMessage &&
      key == other.key &&
      fallback == other.fallback &&
      _equal(arguments, other.arguments);

  @override
  int get hashCode => Object.hash(key, fallback, _hash(arguments));

  /// Serializable transport for persistence and isolate hand-offs.
  Map<String, Object?> toJson() => <String, Object?>{
    'key': key,
    'arguments': arguments,
    'fallback': fallback,
  };

  /// Reads a descriptor without interpreting user strings as catalogue keys.
  factory LocalizedMessage.fromJson(Map<String, Object?> json) {
    final Object? key = json['key'], fallback = json['fallback'];
    final Object? arguments = json['arguments'];
    if (key is! String || fallback is! String || arguments is! Map) {
      throw const FormatException('Invalid localized message');
    }
    return LocalizedMessage(
      key: key,
      fallback: fallback,
      arguments: Map<String, Object?>.unmodifiable(
        arguments.cast<String, Object?>(),
      ),
    );
  }

  /// Preserves dates, durations, enums and nested user maps unambiguously.
  static Object? encodeArgument(Object? value) {
    if (value is LocalizedMessage) {
      return <String, Object?>{'type': 'message', 'value': value.toJson()};
    }
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) {
      return <String, Object?>{
        'type': 'date',
        'value': value.toIso8601String(),
      };
    }
    if (value is Duration) {
      return <String, Object?>{
        'type': 'duration',
        'value': value.inMicroseconds,
      };
    }
    if (value is Enum) {
      return <String, Object?>{'type': 'enum', 'value': value.name};
    }
    if (value is List) {
      return <String, Object?>{
        'type': 'list',
        'value': value.map(encodeArgument).toList(growable: false),
      };
    }
    if (value is Map) {
      return <String, Object?>{
        'type': 'map',
        'value': <String, Object?>{
          for (final MapEntry<Object?, Object?> entry in value.entries)
            entry.key! as String: encodeArgument(entry.value),
        },
      };
    }
    throw ArgumentError.value(value, 'value', 'Unsupported localized argument');
  }

  /// Decodes one named argument, retaining structured user values as data.
  Object? argument(String name) => _decode(arguments[name]);
}

Object? _decode(Object? value) {
  if (value is! Map) return value;
  final Object? payload = value['value'];
  return switch (value['type']) {
    'date' => DateTime.parse(payload! as String),
    'duration' => Duration(microseconds: payload! as int),
    'enum' => payload! as String,
    'message' => LocalizedMessage.fromJson(
      (payload! as Map).cast<String, Object?>(),
    ),
    'list' => (payload! as List).map(_decode).toList(growable: false),
    'map' => <String, Object?>{
      for (final MapEntry<Object?, Object?> entry in (payload! as Map).entries)
        entry.key! as String: _decode(entry.value),
    },
    _ => throw const FormatException('Invalid localized argument'),
  };
}

bool _equal(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every(
          (Object? key) => b.containsKey(key) && _equal(a[key], b[key]),
        );
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_equal(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

int _hash(Object? value) {
  if (value is Map) {
    return Object.hashAllUnordered(
      value.entries.map(
        (MapEntry<Object?, Object?> e) => Object.hash(e.key, _hash(e.value)),
      ),
    );
  }
  if (value is List) return Object.hashAll(value.map(_hash));
  return value.hashCode;
}
