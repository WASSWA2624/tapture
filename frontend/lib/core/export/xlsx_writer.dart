import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';

import 'export_record.dart';
import 'export_request.dart';
import 'photo_index_sheet.dart';
import 'tabular_columns.dart';
import 'value_formatter.dart';
import 'xlsx_book.dart';
import 'xlsx_cell.dart';
import 'xlsx_column.dart';
import 'xlsx_encoder.dart';
import 'xlsx_multi_sheet.dart';
import 'xlsx_photo_refs.dart';
import 'xlsx_sheet.dart';

/// Writes a workbook from an [ExportRequest] (task 018).
///
/// Refined columns sit beside raw ones. The photo index is always present.
/// Cancellation emits nothing and asks the caller to drop the partial file.
final class XlsxWriter {
  /// Text stamped into an export the operator marked incomplete.
  static const String incompleteStamp = 'Marked incomplete';

  /// Encodes [request] and reports progress from 0 to 1.
  static Stream<double> write({
    required ExportRequest request,
    required CancellationToken token,
    required void Function(Uint8List bytes) emit,
    required void Function() discard,
  }) async* {
    if (token.isCancelled) {
      discard();
      return;
    }
    yield 0;
    final XlsxBook book = build(request);
    if (token.isCancelled) {
      discard();
      return;
    }
    emit(XlsxEncoder.encode(book));
    yield 1;
  }

  /// The workbook [write] encodes.
  static XlsxBook build(ExportRequest request, {DateTime? createdUtc}) {
    const ExportValueFormatter formatter = ExportValueFormatter(<String>{});
    final Set<({String id, String name})> templates =
        <({String id, String name})>{
          for (final ExportRecord record in request.records)
            (id: record.templateId, name: record.templateName),
        };
    final List<SheetPlan> plans = XlsxMultiSheet.plan(templates.toList());
    final Map<String, String> sheetOf = <String, String>{
      for (final SheetPlan plan in plans) plan.templateId: plan.sheetName,
    };
    final Map<String, List<ExportRecord>> grouped =
        <String, List<ExportRecord>>{};
    for (final ExportRecord record in request.records) {
      grouped
          .putIfAbsent(record.templateId, () => <ExportRecord>[])
          .add(record);
    }
    final List<XlsxSheet> sheets = <XlsxSheet>[
      for (final MapEntry<String, List<ExportRecord>> group in grouped.entries)
        _sheet(request, formatter, sheetOf[group.key] ?? 'Sheet', group.value),
      PhotoIndexSheet.build(request.records),
    ];
    return XlsxBook(
      sheets: sheets,
      createdUtc: createdUtc ?? DateTime.utc(1970),
    );
  }

  static XlsxSheet _sheet(
    ExportRequest request,
    ExportValueFormatter formatter,
    String name,
    List<ExportRecord> records,
  ) {
    final List<ExportColumn> columns = TabularColumns.plan(request, records);
    final List<String> headers = <String>[
      'Number',
      for (final ExportColumn column in columns) column.header,
      'Photo',
      if (request.markedIncomplete) 'Incomplete',
    ];
    final String mode = request.extras.photoMode;
    return XlsxSheet(
      name: name,
      columns: <XlsxColumn>[
        for (final String header in headers) XlsxColumn(header),
      ],
      rowHeights: <int, double>{
        for (var i = 0; i < records.length; i++)
          i + 1: XlsxPhotoRefs.rowHeight(mode),
      },
      rows: <List<XlsxCell>>[
        for (final ExportRecord record in records)
          <XlsxCell>[
            XlsxCell.text(record.number),
            for (final ExportColumn column in columns)
              _cell(formatter, record, column),
            XlsxCell.text(
              record.photos.isEmpty
                  ? ''
                  : XlsxPhotoRefs.cell(
                      mode: mode,
                      fileName: record.photos.first.storedPath.split('/').last,
                      relativePath: record.photos.first.storedPath,
                    ),
            ),
            if (request.markedIncomplete) const XlsxCell.text(incompleteStamp),
          ],
      ],
    );
  }

  static XlsxCell _cell(
    ExportValueFormatter formatter,
    ExportRecord record,
    ExportColumn column,
  ) {
    final Object? value = formatter.typed(
      TabularColumns.value(record, column),
      TabularColumns.type(record, column),
    );
    return switch (value) {
      num value => XlsxCell.number(value),
      DateTime value => XlsxCell.dateTime(value),
      null => XlsxCell.empty,
      _ => XlsxCell.text(
        formatter.format(
          value,
          TabularColumns.type(record, column),
          ExportFormat.xlsx,
        ),
      ),
    };
  }
}
