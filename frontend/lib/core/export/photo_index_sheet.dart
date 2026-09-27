import 'export_record.dart';
import 'xlsx_cell.dart';
import 'xlsx_column.dart';
import 'xlsx_sheet.dart';

/// One row per photo, included in every workbook (task 018).
final class PhotoIndexSheet {
  /// The index sheet. Records with no photos add no rows.
  static XlsxSheet build(List<ExportRecord> records) {
    final List<List<XlsxCell>> rows = <List<XlsxCell>>[];
    for (final ExportRecord record in records) {
      for (final ExportPhoto photo in record.photos) {
        rows.add(<XlsxCell>[
          XlsxCell.text(record.number),
          XlsxCell.text(photo.type),
          XlsxCell.text(photo.caption),
          XlsxCell.text(photo.storedPath),
        ]);
      }
    }
    return XlsxSheet(
      name: 'Photo index',
      columns: const <XlsxColumn>[
        XlsxColumn('Record'),
        XlsxColumn('Type'),
        XlsxColumn('Caption'),
        XlsxColumn('Path'),
      ],
      rows: rows,
    );
  }
}
