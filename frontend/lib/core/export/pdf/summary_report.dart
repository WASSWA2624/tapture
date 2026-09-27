import '../export_record.dart';
import 'pdf_engine.dart';

/// Counts by context, template, condition and status (task 018).
///
/// Each count is also a labelled line, so a chart is never the only source.
final class SummaryReport {
  /// Aggregated totals and the document that shows them.
  static ({Map<String, int> counts, PdfDocument document}) build({
    required PdfEngine engine,
    required String project,
    required List<ExportRecord> records,
    String conditionKey = 'condition',
  }) {
    final Map<String, int> counts = <String, int>{};
    void add(String group, String key) {
      final String name = '$group:$key';
      counts[name] = (counts[name] ?? 0) + 1;
    }

    for (final ExportRecord record in records) {
      add('context', record.contextPath);
      add('template', record.templateName);
      add('status', record.status);
      String condition = '';
      for (final ExportValue value in record.values) {
        if (value.key == conditionKey) {
          condition = value.finalText ?? value.raw ?? '';
        }
      }
      add('condition', condition);
    }
    return (
      counts: counts,
      document: engine.document(
        title: 'Project summary',
        project: project,
        coverLines: <String>['records ${records.length}'],
        bodyLines: <String>[
          for (final MapEntry<String, int> entry in counts.entries)
            '${entry.key} ${entry.value}',
        ],
      ),
    );
  }
}
