/// One column of an [XlsxSheet]: its bold header, its width and whether its
/// cells wrap.
final class XlsxColumn {
  /// Creates a column. [width] is in spreadsheet character units.
  const XlsxColumn(this.header, {this.width = defaultWidth, this.wrap = false});

  /// The width a column gets when none is given.
  static const double defaultWidth = 16;

  /// The text in row 1.
  final String header;

  /// Width in character units, as a spreadsheet measures it.
  final double width;

  /// Whether long values wrap inside the cell rather than overflow it.
  final bool wrap;
}
