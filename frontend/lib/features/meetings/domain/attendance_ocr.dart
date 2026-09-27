import 'package:tapture/core/constants/app_constants.dart';

import 'attendance_reading.dart';

/// Reads an attendance sheet into one row per line.
///
/// Columns, left to right, are name, title, organisation and whether a
/// signature is present. A header line is skipped. The photo stays evidence
/// whatever this reading produces.
final class AttendanceOcr {
  /// Groups [cells] into rows and names the four columns.
  static List<AttendanceReading> read(List<OcrCell> cells) {
    if (cells.isEmpty) {
      return const <AttendanceReading>[];
    }
    final List<List<OcrCell>> rows = _rows(cells);
    final List<AttendanceReading> readings = <AttendanceReading>[];
    for (final List<OcrCell> row in rows) {
      row.sort((OcrCell a, OcrCell b) => a.x.compareTo(b.x));
      if (_isHeader(row)) {
        continue;
      }
      final OcrCell name = row[0];
      final OcrCell? title = row.length > 1 ? row[1] : null;
      final OcrCell? organisation = row.length > 2 ? row[2] : null;
      final OcrCell? signature = row.length > 3 ? row[3] : null;
      readings.add(
        AttendanceReading(
          name: name.text.trim(),
          title: title?.text.trim() ?? '',
          organisation: organisation?.text.trim() ?? '',
          signaturePresent: _signed(signature?.text ?? ''),
          nameConfidence: name.confidence,
          titleConfidence: title?.confidence ?? 0,
          organisationConfidence: organisation?.confidence ?? 0,
          signatureConfidence: signature?.confidence ?? 0,
        ),
      );
    }
    return readings;
  }

  static List<List<OcrCell>> _rows(List<OcrCell> cells) {
    final List<OcrCell> ordered = List<OcrCell>.of(cells)
      ..sort((OcrCell a, OcrCell b) => a.y.compareTo(b.y));
    final List<List<OcrCell>> rows = <List<OcrCell>>[];
    for (final OcrCell cell in ordered) {
      if (rows.isEmpty ||
          (cell.y - rows.last.first.y).abs() > AppConstants.meetings.rowBand) {
        rows.add(<OcrCell>[cell]);
      } else {
        rows.last.add(cell);
      }
    }
    return rows;
  }

  static bool _isHeader(List<OcrCell> row) {
    final String line = row.map((OcrCell cell) => cell.text).join(' ');
    final String folded = line.toLowerCase();
    return folded.contains('name') && folded.contains('organisation');
  }

  static bool _signed(String text) {
    final String folded = text.trim().toLowerCase();
    if (folded.isEmpty || folded == 'no' || folded == 'absent') {
      return false;
    }
    return true;
  }
}

/// One recognised cell: text, confidence, and its place on the sheet.
typedef OcrCell = ({String text, double confidence, double x, double y});
