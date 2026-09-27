import 'export_record.dart';
import 'export_request.dart';
import 'value_formatter.dart';
import 'xlsx_refined_columns.dart';

/// One CSV file per template, UTF-8 with a byte-order mark (task 018).
final class CsvWriter {
  /// Text stamped when the operator exported an incomplete set.
  static const String incompleteStamp = 'Marked incomplete';

  /// Files keyed by template name. More than one file is the set to zip.
  static Map<String, String> write(ExportRequest request) {
    const ExportValueFormatter formatter = ExportValueFormatter(<String>{});
    final Map<String, List<ExportRecord>> grouped =
        <String, List<ExportRecord>>{};
    for (final ExportRecord record in request.records) {
      grouped
          .putIfAbsent(record.templateName, () => <ExportRecord>[])
          .add(record);
    }
    return <String, String>{
      for (final MapEntry<String, List<ExportRecord>> group in grouped.entries)
        '${group.key}.csv': _file(request, formatter, group.value),
    };
  }

  static String _file(
    ExportRequest request,
    ExportValueFormatter formatter,
    List<ExportRecord> records,
  ) {
    final Set<String> keys = <String>{
      for (final ExportRecord record in records)
        for (final ExportValue value in record.values) value.key,
    };
    final List<String> headers = <String>[
      'Number',
      ...XlsxRefinedColumns.headers(
        keys.toList(),
        refined: request.columns.refined,
      ),
      if (request.markedIncomplete) 'Incomplete',
    ];
    final StringBuffer buffer = StringBuffer('\uFEFF');
    buffer.writeln(_row(headers, request.extras.delimiter));
    for (final ExportRecord record in records) {
      final List<String> cells = <String>[record.number];
      for (final String key in keys) {
        ExportValue? value;
        for (final ExportValue candidate in record.values) {
          if (candidate.key == key) {
            value = candidate;
          }
        }
        cells.add(
          formatter.format(value?.raw, value?.type ?? 'text', ExportFormat.csv),
        );
        if (request.columns.refined) {
          cells.add(
            formatter.format(
              value?.refined,
              value?.type ?? 'text',
              ExportFormat.csv,
            ),
          );
        }
      }
      if (request.markedIncomplete) {
        cells.add(incompleteStamp);
      }
      buffer.writeln(_row(cells, request.extras.delimiter));
    }
    return buffer.toString();
  }

  static String _row(List<String> cells, String delimiter) {
    return cells.map((String cell) => _quote(cell, delimiter)).join(delimiter);
  }

  static String _quote(String cell, String delimiter) {
    final bool needs =
        cell.contains(delimiter) || cell.contains('"') || cell.contains('\n');
    if (!needs) {
      return cell;
    }
    return '"${cell.replaceAll('"', '""')}"';
  }
}
