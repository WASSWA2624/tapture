import 'package:tapture/core/normalise/search_text.dart';

import 'shipped_template_entry.dart';

/// One shipped template's searchable words, each field weighted by how much
/// a match there says about the template (task 076, W16). Built once per
/// loaded library; the words are catalogue data (FE-L10N-07).
final class ShippedSearchDocument {
  /// Creates a document.
  const ShippedSearchDocument({
    required this.templateKey,
    required this.code,
    required this.fields,
  });

  /// Builds the document of [entry], whose own fields read as [fieldLabels].
  factory ShippedSearchDocument.of(
    ShippedTemplateEntry entry, {
    required List<String> fieldLabels,
  }) {
    final ShippedRecordType type = entry.recordType;
    return ShippedSearchDocument(
      templateKey: entry.templateKey,
      code: foldSearchText(entry.code.trim()),
      fields: <({int weight, List<String> words})>[
        (weight: titleWeight, words: searchWords(entry.title)),
        (weight: typeWeight, words: searchWords(entry.code)),
        (weight: typeWeight, words: searchWords(entry.category.title)),
        (weight: typeWeight, words: searchWords('${type.title} ${entry.kind}')),
        (weight: fieldWeight, words: searchWords(fieldLabels.join(' '))),
        (
          weight: areaWeight,
          words: searchWords(entry.category.supergroupTitle),
        ),
        (
          weight: areaWeight,
          words: searchWords(
            '${type.capture} ${type.aiAssistance} ${type.outputs}',
          ),
        ),
      ],
    );
  }

  /// A query that is exactly a template's code.
  static const int codeWeight = 10;

  /// A word of the template's name.
  static const int titleWeight = 5;

  /// A word of its code, category, record type or kind.
  static const int typeWeight = 3;

  /// A word of its own fields' labels.
  static const int fieldWeight = 2;

  /// A word of its area, or of how its record type is captured, assisted
  /// and output.
  static const int areaWeight = 1;

  /// The template this document stands for.
  final String templateKey;

  /// Its code, folded, for an exact match.
  final String code;

  /// Its weighted fields of folded words.
  final List<({int weight, List<String> words})> fields;
}
