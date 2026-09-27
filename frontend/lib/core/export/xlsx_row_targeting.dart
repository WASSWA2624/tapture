/// Resolves each record onto a predefined workbook row (task 018).
final class XlsxRowTargeting {
  /// Matched, not found, or a duplicate match. Not-found rows stay visible.
  static List<RowTarget> resolve({
    required List<String> recordKeys,
    required Map<String, List<int>> rowsByKey,
  }) {
    return <RowTarget>[
      for (final String key in recordKeys)
        () {
          final List<int> rows = rowsByKey[key] ?? const <int>[];
          if (rows.isEmpty) {
            return (recordKey: key, row: null, status: 'notFound');
          }
          if (rows.length > 1) {
            return (recordKey: key, row: rows.first, status: 'duplicate');
          }
          return (recordKey: key, row: rows.single, status: 'matched');
        }(),
    ];
  }

  /// How many planned rows no record filled.
  static int unmatchedCount(List<RowTarget> targets) {
    return targets
        .where((RowTarget target) => target.status == 'notFound')
        .length;
  }
}

/// Where one record landed, or that it did not.
typedef RowTarget = ({String recordKey, int? row, String status});
