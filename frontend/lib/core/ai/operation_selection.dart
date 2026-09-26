import 'dart:convert';

/// Reads and writes the per-operation provider map.
///
/// The map is JSON keyed by `AiOperation.name`:
/// `{"extractFields": {"provider": "…", "model": "…"}}`. It holds ids only,
/// never a key.
abstract final class OperationSelection {
  /// The choices in [raw]. Malformed JSON, and any entry without both a
  /// provider and a model, is skipped rather than guessed.
  static Map<String, OperationChoice> decode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const <String, OperationChoice>{};
    }
    if (decoded is! Map) {
      return const <String, OperationChoice>{};
    }
    return <String, OperationChoice>{
      for (final MapEntry<Object?, Object?> entry in decoded.entries)
        if (entry.key case final String operation when operation.isNotEmpty)
          if (entry.value case final Map<Object?, Object?> choice)
            if (_text(choice[_provider]) case final String provider)
              if (_text(choice[_model]) case final String model)
                operation: (provider: provider, model: model),
    };
  }

  /// [selection] as the stored JSON, keys in a stable order.
  static String encode(Map<String, OperationChoice> selection) {
    final List<String> keys = selection.keys.toList()..sort();
    return jsonEncode(<String, Object?>{
      for (final String key in keys)
        key: <String, String>{
          _provider: selection[key]!.provider,
          _model: selection[key]!.model,
        },
    });
  }
}

/// A provider id and model id chosen for one operation.
typedef OperationChoice = ({String provider, String model});

const String _provider = 'provider';
const String _model = 'model';

String? _text(Object? value) {
  if (value is! String) {
    return null;
  }
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
