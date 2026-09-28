import 'export_record.dart';
import 'export_request.dart';

/// Shared column selection for CSV and XLSX; each switch changes actual output.
abstract final class TabularColumns {
  /// Stable field order with companions immediately beside each field.
  static List<ExportColumn> plan(
    ExportRequest request,
    List<ExportRecord> records,
  ) {
    final Map<String, String> labels = <String, String>{};
    for (final ExportRecord record in records) {
      for (final ExportValue value in record.values) {
        labels.putIfAbsent(
          value.key,
          () => value.label.isEmpty ? value.key : value.label,
        );
      }
    }
    return <ExportColumn>[
      for (final MapEntry<String, String> field
          in labels.entries) ...<ExportColumn>[
        if (request.columns.raw)
          (key: field.key, header: '${field.value} (raw)', role: 'raw'),
        if (request.columns.refined)
          (key: field.key, header: '${field.value} (refined)', role: 'refined'),
        if (!request.columns.raw && !request.columns.refined)
          (key: field.key, header: field.value, role: 'final'),
        if (request.columns.confidence)
          (
            key: field.key,
            header: '${field.value} (confidence)',
            role: 'confidence',
          ),
        if (request.columns.evidence)
          (
            key: field.key,
            header: '${field.value} (evidence)',
            role: 'evidence',
          ),
      ],
    ];
  }

  /// The same source value for every tabular writer.
  static Object? value(ExportRecord record, ExportColumn column) {
    for (final ExportValue value in record.values) {
      if (value.key != column.key) continue;
      return switch (column.role) {
        'raw' => value.raw,
        'refined' => value.refined ?? value.finalText ?? value.raw,
        'confidence' => value.confidence,
        'evidence' => value.evidence,
        _ => value.finalText ?? value.refined ?? value.raw,
      };
    }
    return null;
  }

  /// Declared field type, including numeric confidence companions.
  static String type(ExportRecord record, ExportColumn column) {
    if (column.role == 'confidence') return 'number';
    if (column.role == 'evidence') return 'text';
    for (final ExportValue value in record.values) {
      if (value.key == column.key) return value.type;
    }
    return 'text';
  }
}

/// One field and selected representation.
typedef ExportColumn = ({String key, String header, String role});
