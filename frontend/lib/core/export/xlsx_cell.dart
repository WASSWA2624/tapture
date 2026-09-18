/// One cell value in an [XlsxSheet] row, typed so a spreadsheet opens it as
/// text, a number or a date rather than guessing (FE-CONS-09).
///
/// Dates are wall-clock values: the caller converts to the zone the sheet
/// is labelled with before building the cell.
final class XlsxCell {
  /// A text cell. Control characters that XML cannot carry are dropped when
  /// the workbook is encoded.
  const XlsxCell.text(String this.text)
    : kind = XlsxCellKind.text,
      number = null,
      dateTime = null,
      linkSheet = null,
      linkCell = null;

  /// A number cell.
  const XlsxCell.number(num this.number)
    : kind = XlsxCellKind.number,
      text = null,
      dateTime = null,
      linkSheet = null,
      linkCell = null;

  /// A date-time cell, shown with the workbook's date-time format.
  const XlsxCell.dateTime(DateTime this.dateTime)
    : kind = XlsxCellKind.dateTime,
      text = null,
      number = null,
      linkSheet = null,
      linkCell = null;

  /// A text cell that jumps to [cell] (for example `C4`) on [sheet].
  const XlsxCell.link(
    String this.text, {
    required String this.linkSheet,
    required String this.linkCell,
  }) : kind = XlsxCellKind.link,
       number = null,
       dateTime = null;

  /// A cell with nothing in it.
  static const XlsxCell empty = XlsxCell._empty();

  const XlsxCell._empty()
    : kind = XlsxCellKind.empty,
      text = null,
      number = null,
      dateTime = null,
      linkSheet = null,
      linkCell = null;

  /// A text cell, or [empty] when [value] is null or blank.
  factory XlsxCell.textOrEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return empty;
    }
    return XlsxCell.text(value);
  }

  /// Which constructor built this cell.
  final XlsxCellKind kind;

  /// The text of a text or link cell.
  final String? text;

  /// The value of a number cell.
  final num? number;

  /// The wall-clock value of a date-time cell.
  final DateTime? dateTime;

  /// The sheet a link cell points at.
  final String? linkSheet;

  /// The cell reference a link cell points at.
  final String? linkCell;

  @override
  bool operator ==(Object other) {
    return other is XlsxCell &&
        other.kind == kind &&
        other.text == text &&
        other.number == number &&
        other.dateTime == dateTime &&
        other.linkSheet == linkSheet &&
        other.linkCell == linkCell;
  }

  @override
  int get hashCode {
    return Object.hash(kind, text, number, dateTime, linkSheet, linkCell);
  }
}

/// The value types an [XlsxCell] can hold.
enum XlsxCellKind {
  /// No value.
  empty,

  /// Text, stored once in the shared-string table.
  text,

  /// A number.
  number,

  /// A date and time, stored as a spreadsheet serial.
  dateTime,

  /// Text that jumps to a cell elsewhere in the workbook.
  link,
}
