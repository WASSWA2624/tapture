import 'export_record.dart';
import 'export_request.dart';
import 'tabular_columns.dart';
import 'value_formatter.dart';
import 'xlsx_multi_sheet.dart';

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
          .putIfAbsent(record.templateId, () => <ExportRecord>[])
          .add(record);
    }
    final Map<String, String> names = <String, String>{
      for (final SheetPlan plan
          in XlsxMultiSheet.plan(<({String id, String name})>[
            for (final MapEntry<String, List<ExportRecord>> group
                in grouped.entries)
              (id: group.key, name: group.value.first.templateName),
          ]))
        plan.templateId: plan.sheetName,
    };
    return <String, String>{
      for (final MapEntry<String, List<ExportRecord>> group in grouped.entries)
        '${names[group.key]}.csv': _file(request, formatter, group.value),
    };
  }

  static String _file(
    ExportRequest request,
    ExportValueFormatter formatter,
    List<ExportRecord> records,
  ) {
    final List<ExportColumn> columns = TabularColumns.plan(request, records);
    final List<String> headers = <String>[
      'Number',
      for (final ExportColumn column in columns) column.header,
      if (request.markedIncomplete) 'Incomplete',
    ];
    final StringBuffer buffer = StringBuffer('\uFEFF');
    buffer.writeln(_row(headers, request.extras.delimiter));
    for (final ExportRecord record in records) {
      final List<String> cells = <String>[record.number];
      for (final ExportColumn column in columns) {
        cells.add(
          formatter.format(
            TabularColumns.value(record, column),
            TabularColumns.type(record, column),
            ExportFormat.csv,
          ),
        );
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
        cell.contains(delimiter) ||
        cell.contains('"') ||
        cell.contains('\n') ||
        cell.contains('\r');
    if (!needs) {
      return cell;
    }
    return '"${cell.replaceAll('"', '""')}"';
  }
}
