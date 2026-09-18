import 'xlsx_cell.dart';
import 'xlsx_column.dart';
import 'xlsx_image.dart';

/// One worksheet: a bold header row from [columns], then [rows].
final class XlsxSheet {
  /// Creates a sheet. [name] must already be a valid sheet name; see
  /// [isValidName].
  const XlsxSheet({
    required this.name,
    required this.columns,
    required this.rows,
    this.freezeHeader = false,
    this.autoFilter = false,
    this.images = const <XlsxImage>[],
    this.rowHeights = const <int, double>{},
  });

  /// Tab name. At most 31 characters, none of `[]:*?/\`.
  final String name;

  /// Headers and widths, in order.
  final List<XlsxColumn> columns;

  /// Data rows under the header. A row shorter than [columns] leaves the
  /// rest empty.
  final List<List<XlsxCell>> rows;

  /// Keeps the header row on screen while the data scrolls.
  final bool freezeHeader;

  /// Adds filter buttons to the header row.
  final bool autoFilter;

  /// Pictures anchored to cells on this sheet.
  final List<XlsxImage> images;

  /// Row heights in points, keyed by zero-based row (0 is the header).
  final Map<int, double> rowHeights;

  /// Longest name a spreadsheet accepts for a tab.
  static const int maxNameLength = 31;

  /// Whether [name] can be used as a tab name.
  static bool isValidName(String name) {
    return name.trim().isNotEmpty &&
        name.length <= maxNameLength &&
        !_forbidden.hasMatch(name) &&
        !name.startsWith("'") &&
        !name.endsWith("'");
  }

  /// The spreadsheet column letters for zero-based [index]: 0 is `A`,
  /// 26 is `AA`.
  static String columnName(int index) {
    final List<int> codes = <int>[];
    int remaining = index + 1;
    while (remaining > 0) {
      codes.insert(0, _firstLetter + (remaining - 1) % _alphabet);
      remaining = (remaining - 1) ~/ _alphabet;
    }
    return String.fromCharCodes(codes);
  }

  /// The `A1` reference for zero-based [row] and [column].
  static String cellName(int row, int column) {
    return '${columnName(column)}${row + 1}';
  }
}

final RegExp _forbidden = RegExp(r'[\[\]:*?/\\]');

const int _alphabet = 26;

/// Character code of `A`.
const int _firstLetter = 65;
