import 'xlsx_sheet.dart';

/// A whole workbook for [XlsxEncoder]: its sheets, in tab order, and the
/// document properties a spreadsheet shows under file information.
final class XlsxBook {
  /// Creates a workbook. [createdUtc] stamps the properties and every entry
  /// in the archive, so the same book always encodes to the same bytes.
  const XlsxBook({
    required this.sheets,
    required this.createdUtc,
    this.creator = defaultCreator,
    this.subject = '',
    this.dateTimeFormat = defaultDateTimeFormat,
  });

  /// Author written into the document properties.
  static const String defaultCreator = 'Tapture';

  /// Spreadsheet number format for date-time cells: day first, 24-hour.
  static const String defaultDateTimeFormat = 'dd/mm/yyyy hh:mm:ss';

  /// Tabs, in order. The first is the one the spreadsheet opens on.
  final List<XlsxSheet> sheets;

  /// When the book was made.
  final DateTime createdUtc;

  /// Author in the document properties.
  final String creator;

  /// Subject in the document properties.
  final String subject;

  /// Number format every date-time cell is shown with.
  final String dateTimeFormat;
}
