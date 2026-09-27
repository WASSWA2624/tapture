import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';

import 'export_record.dart';
import 'export_request.dart';
import 'photo_index_sheet.dart';
import 'value_formatter.dart';
import 'xlsx_book.dart';
import 'xlsx_cell.dart';
import 'xlsx_column.dart';
import 'xlsx_encoder.dart';
import 'xlsx_multi_sheet.dart';
import 'xlsx_photo_refs.dart';
import 'xlsx_refined_columns.dart';
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
  static XlsxBook build(ExportRequest request) {
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
    return XlsxBook(sheets: sheets, createdUtc: DateTime.utc(2026, 9, 28));
  }

  static XlsxSheet _sheet(
    ExportRequest request,
    ExportValueFormatter formatter,
    String name,
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
            for (final String key in keys)
              ..._pair(request, formatter, record, key),
            XlsxCell.text(
              record.photos.isEmpty
                  ? ''
                  : XlsxPhotoRefs.cell(
                      mode: mode,
                      fileName: record.photos.first.originalName,
                      relativePath: record.photos.first.storedPath,
                    ),
            ),
            if (request.markedIncomplete) const XlsxCell.text(incompleteStamp),
          ],
      ],
    );
  }

  static List<XlsxCell> _pair(
    ExportRequest request,
    ExportValueFormatter formatter,
    ExportRecord record,
    String key,
  ) {
    ExportValue? value;
    for (final ExportValue candidate in record.values) {
      if (candidate.key == key) {
        value = candidate;
      }
    }
    final String raw = formatter.format(
      value?.raw,
      value?.type ?? 'text',
      ExportFormat.xlsx,
    );
    if (!request.columns.refined) {
      return <XlsxCell>[XlsxCell.text(raw)];
    }
    final String refined = formatter.format(
      value?.refined,
      value?.type ?? 'text',
      ExportFormat.xlsx,
    );
    return <XlsxCell>[XlsxCell.text(raw), XlsxCell.text(refined)];
  }
}
