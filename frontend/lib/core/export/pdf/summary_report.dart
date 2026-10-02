import '../export_record.dart';
import '../export_status_bucket.dart';
import 'pdf_engine.dart';

/// Counts by context, template, condition and status (task 018 step 11),
/// aggregated once and shown as labelled lines with a chart beside each
/// group, so the chart never carries what its lines do not. Status groups
/// are the app's own export summary groups ([ExportStatusBucket]).
final class SummaryReport {
  /// The totals of [records] and the document that shows them. A record's
  /// condition is its first value under one of [conditionKeys].
  static ({Map<String, Map<String, int>> counts, PdfDocument document}) build({
    required PdfEngine engine,
    required String project,
    required List<ExportRecord> records,
    required Set<String> conditionKeys,
    List<String> cover = const <String>[],
  }) {
    final PdfLabels text = engine.labels;
    final Map<String, int> contexts = <String, int>{};
    final Map<String, int> templates = <String, int>{};
    final Map<String, int> conditions = <String, int>{};
    final Map<String, int> statuses = <String, int>{
      for (final ExportStatusBucket bucket in ExportStatusBucket.values)
        bucket.name: 0,
    };
    void add(Map<String, int> group, String key) {
      group[key] = (group[key] ?? 0) + 1;
    }

    for (final ExportRecord record in records) {
      add(contexts, record.contextPath);
      add(templates, record.templateName);
      add(conditions, _condition(record, conditionKeys));
      final ExportStatusBucket? bucket = ExportStatusBucket.of(record.status);
      if (bucket != null) {
        add(statuses, bucket.name);
      }
    }
    final Map<String, String> statusLabels = <String, String>{
      ExportStatusBucket.unprocessed.name: text.unprocessed,
      ExportStatusBucket.needsReview.name: text.needsReview,
      ExportStatusBucket.approved.name: text.approved,
    };
    PdfSection group(
      String heading,
      Map<String, int> counts,
      String Function(String key) label,
    ) {
      final List<PdfBar> bars = <PdfBar>[
        for (final MapEntry<String, int> entry in counts.entries)
          (label: label(entry.key), value: entry.value),
      ];
      return engine.section(
        heading: heading,
        lines: <String>[
          for (final PdfBar bar in bars) '${bar.label}: ${bar.value}',
        ],
        chart: bars,
      );
    }

    return (
      counts: <String, Map<String, int>>{
        'context': contexts,
        'template': templates,
        'condition': conditions,
        'status': statuses,
      },
      document: engine.document(
        title: text.summaryReport,
        project: project,
        coverLines: <String>[...cover, text.recordsCount(records.length)],
        sections: <PdfSection>[
          group(
            text.byContext,
            contexts,
            (String key) => key.isEmpty ? text.noContext : key,
          ),
          group(text.byTemplate, templates, (String key) => key),
          group(
            text.byCondition,
            conditions,
            (String key) => key.isEmpty ? text.noCondition : key,
          ),
          group(text.byStatus, statuses, (String key) => statusLabels[key]!),
        ],
      ),
    );
  }

  static String _condition(ExportRecord record, Set<String> keys) {
    for (final ExportValue value in record.values) {
      if (keys.contains(value.key)) {
        return (value.finalText ?? value.refined ?? value.raw ?? '').trim();
      }
    }
    return '';
  }
}
