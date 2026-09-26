import 'dart:convert';

import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/normalise/choices.dart';

import '../domain/extraction_request.dart';
import '../domain/identifier_extraction.dart';
import '../domain/response_parser.dart';
import 'record_bundle.dart';

/// JSON, option, pattern and summary readers the processing stages share.
///
/// Every reader tolerates malformed stored text and returns an empty or null
/// answer rather than throwing.
abstract final class StageSupport {
  /// The value inside [result], or the failure thrown so the runner can
  /// classify it.
  static T unwrap<T>(Result<T> result) {
    return result.fold(
      (Failure failure) => throw Failure.from(failure),
      (T value) => value,
    );
  }

  /// How [field] is described to an extraction request.
  static ExtractionField extractionField(TemplateField field) {
    return (
      key: field.fieldKey,
      type: field.type,
      requiredField: field.isRequired,
      pattern: pattern(field),
      options: optionValues(field.options),
      optionsHint: null,
    );
  }

  /// The schema a response is parsed against, one entry per field.
  static List<FieldSchema> schema(List<TemplateField> fields) {
    return <FieldSchema>[
      for (final TemplateField field in fields)
        (
          key: field.fieldKey,
          type: field.type,
          requiredField: field.isRequired,
          pattern: pattern(field),
          options: optionLabels(field.options),
        ),
    ];
  }

  /// The template's identity fields that carry a pattern.
  static List<IdentityField> identityFields(RecordBundle bundle) {
    final Set<String> keys = strings(bundle.template.identityFields).toSet();
    return <IdentityField>[
      for (final TemplateField field in bundle.fields)
        if (keys.contains(field.fieldKey) && pattern(field) != null)
          (fieldKey: field.fieldKey, pattern: pattern(field)!),
    ];
  }

  /// The validation pattern on [field], or null when it has none.
  static String? pattern(TemplateField field) {
    final Object? decoded = json(field.validation);
    if (decoded is Map && decoded['pattern'] is String) {
      return decoded['pattern'] as String;
    }
    return null;
  }

  /// The option labels stored in [raw].
  static List<String> optionLabels(String raw) {
    final Object? decoded = json(raw);
    if (decoded is! List) {
      return const <String>[];
    }
    return <String>[
      for (final Object? item in decoded)
        if (item is String)
          item
        else if (item is Map && item['label'] is String)
          item['label'] as String,
    ];
  }

  /// Every label, code and alias stored in [raw].
  static List<String> optionValues(String raw) {
    final List<ChoiceOption> options = choiceOptions(raw);
    return <String>[
      for (final ChoiceOption option in options) ...<String>[
        option.label,
        if (option.code case final String code) code,
        ...option.aliases,
      ],
    ];
  }

  /// The options stored in [raw], in the shape the choice normaliser reads.
  static List<ChoiceOption> choiceOptions(String raw) {
    final Object? decoded = json(raw);
    if (decoded is! List) {
      return const <ChoiceOption>[];
    }
    return <ChoiceOption>[
      for (final Object? item in decoded)
        if (item is String)
          (label: item, code: null, aliases: const <String>[])
        else if (item is Map && item['label'] is String)
          (
            label: item['label'] as String,
            code: item['code'] is String ? item['code'] as String : null,
            aliases: item['aliases'] is List
                ? <String>[
                    for (final Object? alias in item['aliases'] as List)
                      if (alias is String) alias,
                  ]
                : const <String>[],
          ),
    ];
  }

  /// [raw] decoded, or null when it is not JSON.
  static Object? json(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  /// The strings in the JSON list [raw].
  static List<String> strings(String raw) {
    final Object? decoded = json(raw);
    if (decoded is! List) {
      return const <String>[];
    }
    return <String>[
      for (final Object? item in decoded)
        if (item is String) item,
    ];
  }

  /// The string entries in the JSON object [raw].
  static Map<String, String> stringMap(String raw) {
    final Object? decoded = json(raw);
    if (decoded is! Map) {
      return const <String, String>{};
    }
    return <String, String>{
      for (final MapEntry<Object?, Object?> entry in decoded.entries)
        if (entry.key is String && entry.value is String)
          entry.key! as String: entry.value! as String,
    };
  }

  /// Whether [source] marks a value a person entered.
  static bool isManual(String? source) {
    final String folded = source?.toLowerCase() ?? '';
    return folded == 'manual' || folded == 'typed';
  }

  /// The last segment of [path], whichever separator it uses.
  static String basename(String path) {
    return path.replaceAll('\\', '/').split('/').last;
  }

  /// The bounds of [block] as the evidence region JSON.
  static String region(OcrBlock block) {
    return jsonEncode(<String, double>{
      'left': block.bounds.left,
      'top': block.bounds.top,
      'right': block.bounds.right,
      'bottom': block.bounds.bottom,
    });
  }

  /// The non-empty string [key] in the stored request summary [raw].
  static String? summaryValue(String raw, String key) {
    final Object? decoded = json(raw);
    if (decoded is! Map) {
      return null;
    }
    final Object? value = decoded[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Whether [key] is true in the stored request summary [raw].
  static bool summaryBool(String raw, String key) {
    final Object? decoded = json(raw);
    return decoded is Map && decoded[key] == true;
  }
}
