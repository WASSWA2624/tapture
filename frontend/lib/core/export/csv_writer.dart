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
    return <String, String>{
      for (final MapEntry<String, Iterable<String>> file in files(
        request,
      ).entries)
        file.key: file.value.join(),
    };
  }

  /// File names and lazy rows, so native writes retain no complete CSV file.
  static Map<String, Iterable<String>> files(ExportRequest request) {
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
    return <String, Iterable<String>>{
      for (final MapEntry<String, List<ExportRecord>> group in grouped.entries)
        '${names[group.key]}.csv': _lines(request, formatter, group.value),
    };
  }

  /// One UTF-8 table with a byte-order mark: [headers], then [rows], each
  /// cell quoted as [write] quotes it. Used for registers that are not a
  /// template's records, such as a meeting's action register.
  static String table(
    List<String> headers,
    List<List<String>> rows, {
    required String delimiter,
  }) {
    final StringBuffer buffer = StringBuffer('﻿');
    buffer.writeln(_row(headers, delimiter));
    for (final List<String> row in rows) {
      buffer.writeln(_row(row, delimiter));
    }
    return buffer.toString();
  }

  static Iterable<String> _lines(
    ExportRequest request,
    ExportValueFormatter formatter,
    List<ExportRecord> records,
  ) sync* {
    final List<ExportColumn> columns = TabularColumns.plan(request, records);
    final List<String> headers = <String>[
      'Number',
      for (final ExportColumn column in columns) column.header,
      if (request.markedIncomplete) 'Incomplete',
    ];
    yield '\uFEFF${_row(headers, request.extras.delimiter)}\n';
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
      yield '${_row(cells, request.extras.delimiter)}\n';
    }
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
