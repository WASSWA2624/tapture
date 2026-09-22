import 'reference_row.dart';

/// Exact and normalised lookup against a list of [ReferenceRow]s.
///
/// Callers that already hit an indexed key column should prefer that path and
/// only fall back here for in-memory match-column walks.
abstract final class LookupMatcher {
  /// Tries [matchColumns] in order: equality on the raw cell, then a
  /// normalised compare (case, whitespace and punctuation insensitive).
  static List<ReferenceRow> match({
    required List<ReferenceRow> rows,
    required String query,
    required List<String> matchColumns,
    String? keyColumn,
  }) {
    final String trimmed = query.trim();
    if (trimmed.isEmpty || rows.isEmpty) {
      return const <ReferenceRow>[];
    }
    final List<String> columns = matchColumns.isNotEmpty
        ? matchColumns
        : <String>[if (keyColumn != null && keyColumn.isNotEmpty) keyColumn];
    for (final String column in columns) {
      final List<ReferenceRow> exact = <ReferenceRow>[
        for (final ReferenceRow row in rows)
          if (_cell(row, column) == trimmed) row,
      ];
      if (exact.isNotEmpty) {
        return exact;
      }
      final String folded = normalise(trimmed);
      final List<ReferenceRow> soft = <ReferenceRow>[
        for (final ReferenceRow row in rows)
          if (normalise(_cell(row, column)) == folded) row,
      ];
      if (soft.isNotEmpty) {
        return soft;
      }
    }
    return const <ReferenceRow>[];
  }

  /// Case-, whitespace- and punctuation-insensitive fold used by name match.
  static String normalise(String value) {
    final StringBuffer buffer = StringBuffer();
    bool pendingSpace = false;
    for (final int rune in value.trim().toLowerCase().runes) {
      if (_isLetterOrDigit(rune)) {
        if (pendingSpace && buffer.isNotEmpty) {
          buffer.writeCharCode(0x20);
        }
        pendingSpace = false;
        buffer.writeCharCode(rune);
      } else if (rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D) {
        pendingSpace = true;
      } else {
        // Punctuation is dropped rather than treated as a token break.
      }
    }
    return buffer.toString();
  }

  static String _cell(ReferenceRow row, String column) {
    if (column.isEmpty) {
      return row.key;
    }
    return row.values[column] ?? (column == 'key' ? row.key : '');
  }

  static bool _isLetterOrDigit(int rune) {
    return (rune >= 0x30 && rune <= 0x39) ||
        (rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0x41 && rune <= 0x5A) ||
        rune > 0x7F;
  }
}
