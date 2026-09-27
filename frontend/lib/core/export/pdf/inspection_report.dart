import 'pdf_engine.dart';

/// Checklist report in predefined-row order (task 018).
///
/// A row that was never captured is printed as Not found and counted.
final class InspectionReport {
  /// Body lines in [rowOrder], not capture order.
  static PdfDocument build({
    required PdfEngine engine,
    required String project,
    required List<String> rowOrder,
    required Map<String, InspectionRow> captured,
  }) {
    var notFound = 0;
    final List<String> lines = <String>[];
    for (final String key in rowOrder) {
      final InspectionRow? row = captured[key];
      if (row == null) {
        notFound += 1;
        lines.add('$key Not found');
        continue;
      }
      lines.add(
        '$key ${row.result} ${row.observation} ${row.risk} ${row.recommendation}',
      );
    }
    return engine.document(
      title: 'Inspection report',
      project: project,
      coverLines: <String>['rows ${rowOrder.length}', 'not found $notFound'],
      bodyLines: lines,
    );
  }
}

/// One captured checklist row.
typedef InspectionRow = ({
  String result,
  String observation,
  String risk,
  String recommendation,
});
