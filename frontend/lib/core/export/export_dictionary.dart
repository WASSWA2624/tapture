import 'export_record.dart';

/// Describes every exported field so a reader needs no other source.
final class ExportDictionary {
  /// One row per field key seen on [records].
  static List<DictionaryField> describe(List<ExportRecord> records) {
    final Map<String, DictionaryField> fields = <String, DictionaryField>{};
    for (final ExportRecord record in records) {
      for (final ExportValue value in record.values) {
        fields.putIfAbsent(
          value.key,
          () => (
            key: value.key,
            label: value.label,
            type: value.type,
            unit: value.unit ?? '',
            code: value.code ?? '',
            required: false,
            description: value.label,
          ),
        );
      }
    }
    return fields.values.toList();
  }
}

/// One dictionary row.
typedef DictionaryField = ({
  String key,
  String label,
  String type,
  String unit,
  String code,
  bool required,
  String description,
});
