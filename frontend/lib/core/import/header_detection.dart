import 'package:tapture/core/constants/app_constants.dart';

/// Picks the header row from a grid of cell text.
///
/// A title block above the header scores lower than a row of unique labels.
/// The result is a suggestion: the caller always presents it as editable.
abstract final class HeaderDetection {
  /// Scores the first [AppConstants.workbook.headerScanRows] rows of [rows]
  /// and returns the best 1-based row plus its labels.
  static HeaderGuess choose(List<List<String>> rows) {
    final int width = _widthOf(rows);
    if (width == 0 || rows.isEmpty) {
      return (rowNumber: 1, labels: const <String>[], isSuggestion: true);
    }
    final int limit = rows.length < AppConstants.workbook.headerScanRows
        ? rows.length
        : AppConstants.workbook.headerScanRows;
    var bestIndex = 0;
    var bestScore = -1.0;
    for (int index = 0; index < limit; index++) {
      final double score = _score(_padded(rows[index], width), width);
      if (score > bestScore) {
        bestScore = score;
        bestIndex = index;
      }
    }
    return (
      rowNumber: bestIndex + 1,
      labels: _padded(rows[bestIndex], width),
      isSuggestion: true,
    );
  }
}

/// The chosen header row: 1-based [rowNumber], [labels] in column order.
///
/// [isSuggestion] is always true — the caller must let the operator edit it.
typedef HeaderGuess = ({int rowNumber, List<String> labels, bool isSuggestion});

int _widthOf(List<List<String>> rows) {
  var width = 0;
  final int limit = rows.length < AppConstants.workbook.headerScanRows
      ? rows.length
      : AppConstants.workbook.headerScanRows;
  for (int index = 0; index < limit; index++) {
    if (rows[index].length > width) {
      width = rows[index].length;
    }
  }
  return width;
}

List<String> _padded(List<String> row, int width) {
  return <String>[
    for (int index = 0; index < width; index++)
      index < row.length ? row[index].trim() : '',
  ];
}

double _score(List<String> row, int width) {
  var filled = 0;
  var text = 0;
  var numeric = 0;
  final Set<String> unique = <String>{};
  for (final String cell in row) {
    if (cell.isEmpty) {
      continue;
    }
    filled++;
    unique.add(cell.toLowerCase());
    if (_looksMeasured(cell)) {
      numeric++;
    } else {
      text++;
    }
  }
  if (filled == 0 || width == 0) {
    return -1;
  }
  final double density = text / width;
  final double uniqueness = unique.length / filled;
  final double titlePenalty = filled == 1 ? 0.6 : 0;
  final double numberPenalty = numeric / filled;
  return density + uniqueness - titlePenalty - numberPenalty;
}

bool _looksMeasured(String value) {
  final String trimmed = value.trim();
  if (RegExp(r'^-?\d+(\.\d+)?%?$').hasMatch(trimmed)) {
    return true;
  }
  if (RegExp(r'^[£$€]\s?\d').hasMatch(trimmed)) {
    return true;
  }
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(trimmed)) {
    return true;
  }
  if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$').hasMatch(trimmed)) {
    return true;
  }
  return false;
}
